{ config, pkgs, lib, ... }: {
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
    historySubstringSearch.enable = true;
    history = {
      save = 100000;
      size = 100000;
      ignoreDups = true;
      share = lib.mkForce false;
      extended = true;
    };
    initContent = lib.mkAfter ''
      setopt INC_APPEND_HISTORY
      unsetopt HIST_SAVE_BY_COPY
    '';
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
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        identityFile = "~/.ssh/id_rsa_vcs";
        user = "git";
      };
      "*" = {
        addKeysToAgent = "yes";
      };
    };
  };

  services.ssh-agent.enable = true;
}
