{ config, pkgs, lib, ... }: {
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      "url \"git@github.com:\"".insteadOf = "https://github.com/";
      pull.rebase = true;
      merge.conflictstyle = "diff3";
      diff.colorMoved      = "default";
      diff.algorithm       = "patience";
      diff.mnemonicprefix  = true;
      rerere.enabled       = true;
      push.autoSetupRemote = true;
      advice.statusHints   = false;
      apply.whitespace     = "nowarn";
      core.autocrlf        = false;
      merge.verbosity      = 1;
      push.default         = "upstream";
      format.pretty        = "%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset";
      log.date             = "format:%d %b %Y %H:%M:%S %z";
      merge.summary        = true;
      branch.autosetupmerge = true;
    };
    ignores = [
      # editors
      ".idea/" ".vscode/" "*.swp" "*.swo" ".vim/"
      # claude code
      "**/.claude/settings.local.json"
      # direnv
      ".direnv/" ".envrc.local"
      # nix
      "result" "result-*"
      # go
      "vendor/"
      # node
      "node_modules/" "dist/" "coverage/"
      # python
      "__pycache__/" "*.pyc" ".pytest_cache/" ".venv/" "*.egg-info/"
      # java/scala
      "target/" "*.class" ".metals/" ".bloop/" ".bsp/"
      # terraform
      ".terraform/" "*.tfplan" "*.tfstate" "*.tfstate.backup"
      # secrets
      "*.pem" "*.key" ".env" ".env.local"
      # os
      ".DS_Store" "Thumbs.db"
    ];

    settings.alias = {
      # log
      lg              = "log --oneline --graph --decorate --all";
      # diff
      d               = "diff";
      dc              = "diff --cached";
      last            = "diff HEAD^";
      # add
      a               = "add";
      chunkyadd       = "add --patch";
      # branch
      b               = "branch -v";
      # commit
      c               = "commit -m";
      ca              = "commit -am";
      ci              = "commit";
      amend           = "commit --amend";
      # checkout
      co              = "checkout";
      nb              = "checkout -b";
      # cherry-pick
      cp              = "cherry-pick -x";
      # pull/push
      pl              = "pull";
      ps              = "push";
      # rebase
      rc              = "rebase --continue";
      rs              = "rebase --skip";
      # remote
      r               = "remote -v";
      # reset
      undo            = "reset HEAD~1 --mixed";
      uncommit        = "reset --soft HEAD^";
      unstage         = "reset HEAD";
      # stash
      ss              = "stash";
      sl              = "stash list";
      sa              = "stash apply";
      sd              = "stash drop";
      # status
      s               = "status";
      st              = "status";
      # mergetool
      mt              = "mergetool";
      # misc
      filelog         = "log -u";
      t               = "tag -n";
      contributors    = "shortlog --summary --numbered --email";
      recent-branches = "!git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
      snapshot        = "!git stash save \"snapshot: $(date)\" && git stash apply stash@{0}";
      snapshots       = "!git stash list --grep snapshot";
    };
    includes = [{ path = "~/.config/git/user"; }];
  };

  programs.delta = {
    enable                = true;
    enableGitIntegration  = true;
    options = {
      navigate     = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "Catppuccin Mocha";
    };
  };

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable           = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gnome3;
    defaultCacheTtl  = 28800;
    maxCacheTtl      = 86400;
  };

  home.activation.reloadGpgAgent = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.gnupg}/bin/gpg-connect-agent reloadagent /bye > /dev/null 2>&1 || true
  '';

  programs.nix-index = {
    enable               = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit -C";
    historySubstringSearch.enable = true;
    history = {
      save        = 100000;
      size        = 100000;
      ignoreDups  = true;
      extended    = true;
      ignoreSpace = true;
    };
    sessionVariables = {
      LESS                       = "-F -g -i -M -R -S -w -X -z-4";
      CLOUDSDK_PYTHON_SITEPACKAGES              = "1";
      CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK = "true";
      ZSH_DISABLE_COMPFIX        = "true";
    };
    plugins = [
      {
        name = "powerlevel10k";
        src  = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
    initContent = ''
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      # vi-mode: change cursor shape and reset prompt on mode change
      export VI_MODE_SET_CURSOR=true
      export VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true

      # show current kube context on the right
      export RPS1='$(kubectx_prompt_info)'

      # run a command in every immediate subdirectory
      function run_in_subdirs() {
        local cmd="$@"
        for dir in */; do
          [[ -d "$dir" ]] || continue
          echo "\n==> $dir"
          (cd "$dir" && eval "$cmd")
        done
      }
      alias rsub=run_in_subdirs

      # list open PRs for a GitHub org, optionally filtered by topic
      function gh_prs() {
        local org="''${1:?Usage: gh_prs <org> [topic]}"
        local topic="$2"
        local filter=""
        [[ -n "$topic" ]] && filter="--topic $topic"
        gh repo list "$org" --limit 1000 $filter --json name -q '.[].name' | \
          while read repo; do
            gh pr list --repo "$org/$repo" --state open --json title,url,author
          done | jq -cr '.[] | select(. != null) | "title: \(.title)\nurl:   \(.url) (\(.author.login))\n"'
      }

      # source local zsh config (private aliases, tokens, work-specific stuff)
      [[ ! -f ~/.config/zsh/local.zsh ]] || source ~/.config/zsh/local.zsh
    '';
    shellAliases = {
      ls  = "eza --icons";
      ll  = "eza -la --git --icons";
      la  = "eza -a --icons";
      lt  = "eza --tree --icons";
      cat = "bat --paging=never";
      man = "batman";
    };
    oh-my-zsh = {
      enable  = true;
      theme   = "";
      plugins = [
        "docker"
        "gh"
        "git"
        "golang"
        "helm"
        "history"
        "kind"
        "kubectl"
        "kubectx"
        "minikube"
        "python"
        "sbt"
        "sudo"
        "terraform"
        "tmux"
        "vi-mode"
      ];
    };
  };

  programs.tmux = {
    enable        = true;
    terminal      = "tmux-256color";
    historyLimit  = 50000;
    keyMode       = "vi";
    prefix        = "C-a";
    baseIndex     = 1;
    mouse         = true;
    escapeTime    = 0;
    focusEvents   = true;
    clock24       = true;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      fzf-tmux-url
      tmux-fzf
      vim-tmux-navigator
      prefix-highlight
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_status_modules_right "prefix_highlight session date_time"
          set -g @catppuccin_date_time_text "%d %b %Y %H:%M"
          set -g @catppuccin_window_status_style "rounded"
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    extraConfig = ''
      # true color
      set -as terminal-features ",xterm-256color:RGB"

      # status bar at top
      set -g status-position top

      # window numbering
      set -g renumber-windows on
      setw -g pane-base-index 1

      # intuitive splits (open in current path)
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # copy mode vi bindings
      bind -T copy-mode-vi v   send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y   send-keys -X copy-selection-and-cancel

      # send prefix to nested tmux (e.g. remote SSH session)
      bind a send-prefix

      # reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"
    '';
  };

  home.file.".ssh/config".text = ''
    ControlMaster auto
    ControlPath /tmp/%r@%h:%p

    Host *
      AddKeysToAgent yes
      Compression yes

    Include ~/.ssh/config.d/*
  '';

  home.file.".ssh/config.d/.keep".text = "";


  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.sessionVariables = {
    EDITOR   = "nvim";
    VISUAL   = "nvim";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };
}
