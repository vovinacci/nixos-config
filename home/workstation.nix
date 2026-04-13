{ config, pkgs, ... }: {
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
      ".mozilla"
      ".config/slack"
      ".local/share/direnv"
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
    slack
    jetbrains.idea
    tmux
    direnv
  ];
}
