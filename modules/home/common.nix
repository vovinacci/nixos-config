{ config, pkgs, ... }: {
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
      merge.summary        = true;
      branch.autosetupmerge = true;
    };
    ignores = [
      # editors
      ".idea/" ".vscode/" "*.swp" "*.swo" ".vim/"
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
      lg              = "log --oneline --graph --decorate --all";
      undo            = "reset HEAD~1 --mixed";
      uncommit        = "reset --soft HEAD^";
      last            = "diff HEAD^";
      filelog         = "log -u";
      t               = "tag -n";
      contributors    = "shortlog --summary --numbered --email";
      recent-branches = "!git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
      snapshot        = "!git stash save \"snapshot: $(date)\" && git stash apply stash@{0}";
      snapshots       = "!git stash list --grep snapshot";
    };
    includes = [{ path = "~/.gitconfig.user"; }];
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
    enable          = true;
    pinentry.package = pkgs.pinentry-gnome3;
    defaultCacheTtl = 28800;
    maxCacheTtl     = 86400;
  };

  programs.nix-index = {
    enable             = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;
    history = {
      save        = 100000;
      size        = 100000;
      ignoreDups  = true;
      extended    = true;
      ignoreSpace = true;
    };
    sessionVariables.LESS = "-F -g -i -M -R -S -w -X -z-4";
    plugins = [
      {
        name = "powerlevel10k";
        src  = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
    initContent = ''
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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
            gh pr list --repo "$org/$repo" --state open --json title,url,author \
              --jq '.[] | "\(.title) \(.url) [\(.author.login)]"'
          done
      }
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
        "git"
        "sudo"
        "docker"
        "kubectl"
        "kubectx"
        "tmux"
        "gh"
        "golang"
        "helm"
        "terraform"
        "history"
        "vi-mode"
      ];
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
