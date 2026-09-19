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
    # Keep >= boot.loader.systemd-boot.configurationLimit (10), or the boot
    # menu gets starved. See docs/operations.md.
    clean.extraArgs = "--keep 10";
  };

  nixpkgs.config.allowUnfree = true;

  # Keep /etc/nixos owned by primary user so rebuilds don't require sudo for editing
  systemd.tmpfiles.rules = [
    "d /etc/nixos 0755 ${username} users -"
  ];

  # Fleet-wide base and rescue tooling. The interactive shell tools (ripgrep,
  # fzf, bat, eza, ...) are workstation concerns, in modules/system/shell.nix.
  programs.git.enable = true;

  programs.neovim = {
    enable        = true;
    defaultEditor = true;   # EDITOR / VISUAL
    viAlias       = true;
    vimAlias      = true;
    # Plugins and language servers come from the user's own config (lazy.nvim +
    # mason), not from the remote-plugin providers.
    withRuby    = false;
    withPython3 = false;
  };

  environment.systemPackages = with pkgs; [
    curl wget
    fd htop btop
    file         # what a file is, by content
    lsof         # what holds a file or port open
    iotop-c      # which process is doing the I/O
    pciutils usbutils
    # Disk health: smartctl for SATA/USB disks, nvme for the NVMe drives.
    smartmontools nvme-cli
    # Partitioning, for the pools on partitions: sgdisk edits the table,
    # partprobe (parted) makes the kernel re-read it without a reboot.
    gptfdisk parted
    # fuser (what holds a mount open before export/umount), killall, pstree.
    psmisc
    # Inspect and repair btrfs filesystems on attached disks; nothing here
    # mounts btrfs, so the module does not pull the tools in by itself.
    btrfs-progs
    # mkfs.vfat and fsck for ESPs and FAT32 sticks.
    dosfstools
    # Windows install images: split install.wim into FAT32-sized parts, inspect,
    # verify.
    wimlib
    # NTFS read-write through FUSE. For writing to a Windows volume, `-o inherit`
    # gives new files the parent folder's permissions, so Windows treats them as
    # its own; the in-kernel ntfs3 driver has no equivalent.
    ntfs3g
    yubikey-manager
    yubikey-personalization
    pcsc-tools
  ];

  programs.nix-ld.enable = true;
  # Added to nix-ld's default set (zlib, openssl, curl, ...) for runtimes that
  # mise and mason download: native Python wheels, Ruby gems, REPLs.
  programs.nix-ld.libraries = with pkgs; [
    libffi
    readline
    ncurses
    sqlite
    libyaml
  ];

  # Virtual CD/DVD drives: vhba module, vhba_ctl udev rule for the cdrom group,
  # D-Bus activated cdemu-daemon user service, and the CLI client.
  programs.cdemu = {
    enable         = true;
    gui            = false;
    image-analyzer = false;
  };

  # Compressed RAM swap, used before the disk swap (priority 5 vs the disk's
  # default negative priority), so the disk swap is only a spill-over.
  zramSwap.enable = true;

  services.fwupd.enable = true;

  # /var/log is persisted (hosts/darkhero/impermanence.nix), so the journal
  # grows without bound - 741 MB accumulated over the first four months. At
  # roughly 170 MB/month, 2G is about a year of retention.
  services.journald.extraConfig = ''
    SystemMaxUse=2G
  '';

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
