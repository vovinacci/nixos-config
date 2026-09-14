{ config, lib, pkgs, username, ... }: {
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

  # ESP readable by root only. The generated fmask/dmask=0022 leave
  # loader/random-seed world-readable (bootctl warns "security hole"), and
  # nixos-generate-config copies whatever mask is mounted, so regenerating
  # hardware-configuration.nix would not fix it.
  fileSystems."/boot/efi".options = lib.mkForce [ "fmask=0077" "dmask=0077" ];

  boot.kernelParams = [
    # The root filesystem is on a USB SSD; USB autosuspend can put the device
    # or its port to sleep under the running system. Removable if the root
    # filesystem moves off USB.
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
    # Render a panic as a QR code of the kernel log. amdgpu registers with the
    # drm panic handler, so this works from inside a Wayland session.
    "drm.panic_screen=qr_code"
  ];
  # Diagnostics for the USB root dropout (see IOWriteBandwidthMax comment).
  #
  # When the enclosure leaves the bus, btrfs reports `bdev <missing disk>` and
  # the kernel survives with no root, and journald cannot write anything
  # because /var/log is on the disk that just vanished. It does not panic
  # right away: in the 2026-09-13 dropout (captured by pstore) the disk left
  # the bus at 262 s, and the panic only came at 1315 s, when systemd (PID 1)
  # segfaulted paging from the vanished root. A reset before that point leaves
  # no record except the console, and consoleLogLevel=4 (the NixOS default)
  # suppresses the KERN_INFO `USB disconnect` line that says why.
  #
  # consoleLogLevel=7 puts the USB and xHCI messages back on screen, and
  # drm.panic_screen=qr_code makes any panic render the whole ring buffer as a
  # photographable QR code rather than a wall of scrolling text. The panic is
  # also written to EFI pstore and archived to /var/lib/systemd/pstore (on
  # /persist, see impermanence.nix) on the next boot.
  boot.consoleLogLevel = 7;

  # Panic when btrfs itself hits a fatal error. Merged into the option lists in
  # hardware-configuration.nix, which is generated and must not be edited by
  # hand. Note that this does not cover the disk vanishing: that surfaces as a
  # transaction abort, which only forces the filesystem read-only (observed
  # 2026-09-13: "Transaction aborted (error -5)" then "forced readonly", no
  # panic).
  fileSystems."/nix".options     = [ "fatal_errors=panic" ];
  fileSystems."/home".options    = [ "fatal_errors=panic" ];
  fileSystems."/persist".options = [ "fatal_errors=panic" ];

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

    # waybar's default thermal_zone0 is "INT3400 Thermal", a constant 20 C on
    # this board. coretemp's temp1 is the CPU package temperature.
    programs.waybar.settings.mainBar.temperature = {
      hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
      input-filename = "temp1_input";
    };
  };

  system.stateVersion = "26.05";
}
