{ config, pkgs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix
  ];

  networking.hostName = "darkhero";

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    systemd-boot = {
      enable = true;
      # /boot/efi is 512M and each generation costs ~95M (14M kernel + 81M
      # initrd), so anything above 4 fills the ESP mid-install.
      configurationLimit = 4;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.extraModulePackages = [ config.boot.kernelPackages.vhba ];
  boot.kernelModules = [ "vhba" ];

  # vhba ships no udev rule, so /dev/vhba_ctl defaults to root:root 0600 and the
  # user cdemu-daemon cannot open it. Grant the cdrom group access.
  services.udev.extraRules = ''
    KERNEL=="vhba_ctl", SUBSYSTEM=="misc", GROUP="cdrom", MODE="0660"
  '';
  boot.kernelParams = [
    "rootdelay=20"
    "usbcore.autosuspend=-1"
    # Root SSD (Transcend ESD310C, 2174:2100) is a USB device. Forces BOT by
    # disabling UAS for this bridge.
    #
    # The original rationale - "UAS link resets corrupt the FS" - is not
    # supported by evidence gathered 2026-08-24. SMART reports 0 media and data
    # integrity errors and 0 controller error-log entries over 1.55 TB written,
    # and no BTRFS error has ever appeared in the journal. The panics have a
    # measured thermal cause instead; see the nix-daemon IOWriteBandwidthMax
    # comment below. (The comment also claimed the drive sits behind an ASMedia
    # ASM1074 hub; `lsusb -t` shows it directly on the root hub.)
    #
    # Kept anyway, for a different reason than it was added: BOT forces
    # queue_depth=1, which caps throughput and therefore caps heat. That is why
    # disabling UAS made the panics less frequent without stopping them.
    # Re-enabling UAS would restore queueing and IOPS, but only makes sense
    # once the thermal ceiling is handled - retest before touching it.
    "usb-storage.quirks=2174:2100:u"
  ];
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.sops.yaml;
    # SSH key bind mount from impermanence happens after neededForUsers secrets run.
    # Use a dedicated age key on /persist (mounted in stage-1, always available).
    age.sshKeyPaths = [];
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";
    age.generateKey = false;
  };

  # Cap nix-daemon's write bandwidth to the root SSD.
  #
  # The root filesystem lives on a Transcend ESD310C in a stick-format USB
  # enclosure with no heatsink. Measured on 2026-08-24: sustained sequential
  # writes reach 788 MB/s and take the controller from 53 C to 76 C in 61
  # seconds, still climbing linearly when the test was aborted. A `nh os
  # switch` with a large update writes at exactly that rate for minutes, which
  # is enough to reach thermal cutoff - the bridge drops off the bus, the root
  # filesystem disappears mid-write, and the kernel panics with nothing left to
  # log it. SMART agrees: 12 unsafe shutdowns in 17 power cycles, alongside 0
  # media errors and 0 controller error-log entries. The drive is healthy; it
  # just overheats.
  #
  # Capped to 200 MB/s the same workload plateaus at 66 C and holds there
  # indefinitely (verified flat over 180 s from an already-warm 59 C start).
  # cgroup v2 io.max throttles buffered writeback here, not just direct I/O
  # (measured 189 MB/s capped versus 725 MB/s uncapped), so this binds the path
  # nix actually uses.
  #
  # Removable if the root filesystem ever moves off USB, or if the enclosure
  # gets real cooling. Raising the cap is safe only with a re-measured plateau.
  systemd.services.nix-daemon.serviceConfig.IOWriteBandwidthMax =
    "/dev/disk/by-id/usb-ESD310C_TS1TESD310C_50277198J67441980079-0:0 200M";

  # Host-specific home-manager settings. Shared modules under modules/home/
  # must stay machine-agnostic, so the physical display and this machine's
  # geographic position live here rather than in modules/home/sway.nix.
  home-manager.users.${username} = {
    wayland.windowManager.sway.config.output."DP-2" = {
      mode  = "3840x2160@143.963Hz";
      scale = "1.0";
    };

    services.wlsunset = {
      enable    = true;
      latitude  = 50.4;   # Kyiv
      longitude = 30.5;
    };
  };

  system.stateVersion = "26.05";
}
