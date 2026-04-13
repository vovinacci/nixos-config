{ config, pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias  = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      rust-analyzer
      gopls
      pyright
      jdt-language-server

      # tools
      ripgrep
      fd
      tree-sitter
    ];
  };
}
