{ config, pkgs, ... }: {
  imports = [
    ../modules/home/common.nix
    ../modules/home/neovim.nix
    ../modules/home/sway.nix
    ../modules/home/foot.nix
    ../modules/home/firefox.nix
    ../modules/home/dev.nix
    ../modules/home/fonts.nix
    ../modules/home/media.nix
    ../modules/home/apps.nix
    ../modules/home/gaming.nix
  ];

  home.username      = "vovin";
  home.homeDirectory = "/home/vovin";
  home.stateVersion  = "26.05";

  home.persistence."/persist" = {
    directories = [
      "Downloads"
      "Documents"
      "src"
      ".ssh"
      ".gnupg"
      ".config/sway"
      ".config/nvim"
      ".config/git"
      ".config/slack"
      ".config/Signal"
      ".config/spotify"
      ".config/teams-for-linux"
      ".config/zoom"
      ".mozilla"
      ".local/share/direnv"
      ".local/share/Steam"
      ".steam"
    ];
    files = [
      ".zsh_history"
    ];
  };

  programs.git = {
    enable = true;
    settings = {
      user.name  = "Volodymyr Shcherbinin (vovin)";
      user.email = "vovin@lurk.kiev.ua";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    history = {
      size = 100000;
      ignoreDups = true;
      share = true;
    };
  };

  home.packages = with pkgs; [
    jetbrains.idea
  ];
}
