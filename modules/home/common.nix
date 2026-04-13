{ config, pkgs, ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.name  = "vovin";
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

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 50000;
    keyMode = "vi";
    prefix = "C-a";
    extraConfig = ''
      set -g mouse on
      set -sg escape-time 0
    '';
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
  };
}
