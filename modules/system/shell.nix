{ pkgs, ... }: {
  # Interactive shell and terminal tooling. Binaries only: shell init (zsh
  # plugins, atuin/zoxide/fzf hooks), git, tmux and yazi configuration live in
  # the user's dotfiles, so the programs.{atuin,zoxide,fzf,bat} NixOS modules -
  # which inject system-wide shell init - are deliberately not used.
  environment.systemPackages = with pkgs; [
    # zsh framework and plugins. Data, not configuration: nothing here is
    # loaded unless ~/.zshrc sources it. Installing them systemwide gives the
    # user's dotfiles a stable path to source
    # (/run/current-system/sw/share/...) instead of a /nix/store path that
    # breaks at the next garbage collection.
    oh-my-zsh
    zsh-powerlevel10k
    zsh-fzf-tab
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search

    ripgrep
    fzf
    zoxide
    atuin
    eza
    bat
    bat-extras.batman
    delta        # git pager
    difftastic   # structural diff, on demand
    tmux

    # yazi previewer / action plugin runtime deps
    mediainfo
    glow
    ouch
  ];

  # The system profile links only the directories in environment.pathsToLink.
  # `/share/zsh` is there by default (so powerlevel10k, zsh-autosuggestions and
  # zsh-history-substring-search arrive under share/zsh/{themes,plugins}), but
  # these three install to a directory of their own and would be dropped from
  # the profile without being listed here - the package is in the closure, yet
  # nothing appears under /run/current-system/sw/share.
  environment.pathsToLink = [
    "/share/oh-my-zsh"
    "/share/fzf-tab"
    "/share/zsh-syntax-highlighting"
  ];

  # Package only: an empty settings/plugins set leaves YAZI_CONFIG_HOME unset,
  # so yazi reads ~/.config/yazi.
  programs.yazi.enable = true;

  # gpg-agent is the SSH agent (YubiKey): user sockets for gpg-agent and its
  # ssh emulation, SSH_AUTH_SOCK, and pinentry-program in /etc/gnupg.
  programs.gnupg.agent = {
    enable           = true;
    enableSSHSupport = true;
    pinentryPackage  = pkgs.pinentry-qt;
  };

  # Route gpg through pcscd (services.pcscd in common.nix). scdaemon's built-in
  # CCID driver claims the YubiKey's USB interface exclusively, which leaves
  # pcscd with "No reader found" and breaks ykman piv and age-plugin-yubikey.
  environment.etc."gnupg/scdaemon.conf".text = ''
    disable-ccid
  '';

  # `,` runs any nixpkgs binary without installing it.
  programs.nix-index-database.comma.enable = true;
}
