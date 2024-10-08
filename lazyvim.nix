{ lib
, stdenv
, fetchFromGitHub
, fetchpatch
, makeWrapper
, cargo
, curl
, fd
, fzf
, git
, gnumake
, gnused
, gnutar
, gzip
, lua-language-server
, neovim
, nodejs
, nodePackages
, ripgrep
, tree-sitter
, unzip
, nvimAlias ? false
, viAlias ? false
, vimAlias ? false
, globalConfig ? ""
}:

stdenv.mkDerivation (finalAttrs: {
  inherit nvimAlias viAlias vimAlias globalConfig;

  pname = "lazyvim";
  version = "4.25.1"; # Replace with the actual version you want to use

  src = fetchFromGitHub {
    owner = "LazyVim";
    repo = "LazyVim";
    rev = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with the actual hash
  };

  # If no patches are needed, you can leave this empty
  patches = [ ];

  nativeBuildInputs = [
    gnused
    makeWrapper
  ];

  runtimeDeps = [
    stdenv.cc
    cargo
    curl
    fd
    fzf
    git
    gnumake
    gnutar
    gzip
    lua-language-server
    neovim
    nodejs
    nodePackages.neovim
    ripgrep
    tree-sitter
    unzip
  ];

  buildPhase = ''
    runHook preBuild
    # Create the directory to hold LazyVim's files
    mkdir -p share/lazyvim
    # Copy necessary files to share/lazyvim
    cp init.lua health.lua types.lua share/lazyvim/
    cp -r lua config plugins util share/lazyvim/
    # Create the bin directory and the launcher script
    mkdir bin
    cat > bin/lazyvim <<'EOF'
#!/usr/bin/env bash
# Copy the configuration to the user's config directory if it doesn't exist
if [ ! -d "$HOME/.config/lazyvim" ]; then
  mkdir -p "$HOME/.config/lazyvim"
  cp -r "@lazyvim_share_dir@"/* "$HOME/.config/lazyvim/"
fi
# Set NVIM_APPNAME to use the lazyvim configuration directory
export NVIM_APPNAME="lazyvim"
# Launch Neovim
exec nvim "$@"
EOF
    chmod +x bin/lazyvim
    # Substitute the placeholder with the actual path to share/lazyvim
    substituteInPlace bin/lazyvim \
      --replace "@lazyvim_share_dir@" "$out/share/lazyvim" \
      --replace nvim ${neovim}/bin/nvim
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin share $out
    wrapProgram $out/bin/lazyvim \
      --prefix PATH : ${ lib.makeBinPath finalAttrs.runtimeDeps } \
      --prefix LD_LIBRARY_PATH : ${stdenv.cc.cc.lib} \
      --prefix CC : ${stdenv.cc.targetPrefix}cc
  '' + lib.optionalString finalAttrs.nvimAlias ''
    ln -s $out/bin/lazyvim $out/bin/nvim
  '' + lib.optionalString finalAttrs.viAlias ''
    ln -s $out/bin/lazyvim $out/bin/vi
  '' + lib.optionalString finalAttrs.vimAlias ''
    ln -s $out/bin/lazyvim $out/bin/vim
  '' + ''
    runHook postInstall
  '';

  meta = with lib; {
    description = "A Neovim configuration powered by LazyVim";
    homepage = "https://github.com/LazyVim/LazyVim";
    license = licenses.mit;
    maintainers = with maintainers; [ yourUsername ]; # Replace with your GitHub username
    platforms = platforms.unix;
    mainProgram = "lazyvim";
  };
})
