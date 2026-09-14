# Neovim config lives in ~/src/vovinacci/nvim-config
# (https://github.com/vovinacci/nvim-config, lazy.nvim + mason based).
# Out-of-store symlink keeps it editable and git-managed outside the store.
# programs.neovim only wraps the binary here. Its generated initLua is never
# empty (it always disables the node/perl/python3/ruby providers), so
# sideloadInitLua passes it through the wrapper instead of writing
# nvim/init.lua into the symlinked config directory. Mason-installed binaries
# run via nix-ld (enabled in modules/system/common.nix).
#
# Same split as git: a plain nvim stays in the system layer for root and
# rescue use, this module owns the user's configured one.
{ config, pkgs, ... }: {
  programs.neovim = {
    enable        = true;
    defaultEditor = true;   # EDITOR / VISUAL
    viAlias       = true;
    vimAlias      = true;
    sideloadInitLua = true;

    # On nvim's own PATH (wrapper), not the global one. nvim-lspconfig finds
    # the servers there; fd comes from the system layer and ripgrep from
    # programs.ripgrep in dev.nix, both already on PATH.
    extraPackages = with pkgs; [
      lua-language-server
      nil
      typescript-language-server
      vscode-langservers-extracted
      rust-analyzer
      gopls
      pyright
      jdt-language-server
      tree-sitter
    ];
  };

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/src/vovinacci/nvim-config";
}
