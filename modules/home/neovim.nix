# Neovim config lives in ~/src/vovinacci/nvim-config
# (https://github.com/vovinacci/nvim-config, lazy.nvim + mason based).
# Out-of-store symlink keeps it editable and git-managed outside the store.
# No programs.neovim: it generates its own init.lua, which conflicts with
# symlinking the whole config directory. Mason-installed binaries run via
# nix-ld (enabled in modules/system/common.nix).
#
# The nvim binary and fd come from the system layer (root-shell tooling in
# modules/system/common.nix); ripgrep from programs.ripgrep in dev.nix.
{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    # LSP servers (found on PATH by nvim-lspconfig)
    lua-language-server
    nil
    typescript-language-server
    vscode-langservers-extracted
    rust-analyzer
    gopls
    pyright
    jdt-language-server

    # tools
    tree-sitter
  ];

  home.shellAliases = {
    vi  = "nvim";
    vim = "nvim";
  };

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/src/vovinacci/nvim-config";
}
