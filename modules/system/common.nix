{ config, pkgs, username, ... }: {
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    # root is already trusted by the nixpkgs default; the user is in wheel.
    trusted-users = [ "@wheel" ];
  };

  # Flake-only system: nixPath and the registry are pinned to the flake's
  # nixpkgs, so the channel mechanism (and the root channel left over from
  # installation) only adds a second, stale nixpkgs to NIX_PATH.
  nix.channel.enable = false;

  programs.nh = {
    enable = true;
    # Exports NH_FLAKE, so `nh os switch` needs no path argument. `-H darkhero`
    # is also unnecessary - nh defaults the host to the current hostname.
    flake = "/etc/nixos";
    clean.enable = true;
    clean.dates = "weekly";
    # Keep >= boot.loader.systemd-boot.configurationLimit (4), or the boot menu
    # gets starved. See docs/operations.md.
    clean.extraArgs = "--keep 5 --keep-since 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # Keep /etc/nixos owned by primary user so rebuilds don't require sudo for editing
  systemd.tmpfiles.rules = [
    "d /etc/nixos 0755 ${username} users -"
  ];

  # Root-shell and rescue tooling only. ripgrep, fzf, bat and eza are owned by
  # their home-manager programs.* modules.
  environment.systemPackages = with pkgs; [
    git curl wget neovim
    fd htop btop
    pciutils usbutils
    yubikey-manager
    yubikey-personalization
    pcsc-tools
  ];

  programs.nix-ld.enable = true;

  # Virtual CD/DVD drives: vhba module, vhba_ctl udev rule for the cdrom group,
  # D-Bus activated cdemu-daemon user service, and the CLI client.
  programs.cdemu = {
    enable         = true;
    gui            = false;
    image-analyzer = false;
  };

  # Compressed RAM swap, used before the disk swap (priority 5 vs the disk's
  # default negative priority). The disk swap sits on the root USB SSD, whose
  # heat is the reason for the nix-daemon write cap in hosts/darkhero.
  zramSwap.enable = true;

  services.fwupd.enable = true;

  # /var/log is persisted (hosts/darkhero/impermanence.nix), so the journal
  # grows without bound - 741 MB accumulated over the first four months. At
  # roughly 170 MB/month, 2G is about a year of retention.
  services.journald.settings.Journal.SystemMaxUse = "2G";

  services.pcscd.enable = true;
  # Restarting pcscd drops every open PC/SC session, which kills an in-flight
  # YubiKey PIV/GPG session mid-rebuild. Leave the running daemon alone on
  # switch; a reboot picks up any new version.
  systemd.services.pcscd.restartIfChanged = false;

  hardware.enableRedistributableFirmware = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    # ed25519 only. The default list also has RSA, whose key is not persisted
    # on the tmpfs root and so was regenerated on every boot.
    hostKeys = [
      { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; }
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  security.sudo.extraConfig = ''
    Defaults env_keep += "HOME EDITOR VISUAL"
  '';

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    useXkbConfig = true;
  };

  services.xserver.xkb = {
    layout  = "us,ua";
    options = "grp:ctrl_space_toggle,compose:ralt";
  };
}
