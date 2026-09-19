{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
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
      # /boot/efi is 2 GiB; each distinct kernel + initrd pair costs ~90M and
      # generations sharing a pair share its files, so 10 fits with room to spare.
      # Keep programs.nh.clean's --keep (modules/system/common.nix) >= this.
      configurationLimit = 10;
      # Firmware text mode 2. "keep" inherits the firmware's 80x25 and "max"
      # renders the 8x19 firmware font at full 4K, too small to read. In the
      # menu, `r` cycles the modes and `p` shows the current one.
      consoleMode = "2";
      # Windows 11 has its own ESP on the other NVMe, which systemd-boot cannot
      # auto-detect, so it is reached through that ESP's EFI device handle.
      # The handle is not stable across disk changes - re-check it with the
      # EDK2 shell as described in docs/operations.md.
      windows."11" = {
        title = "Windows 11";
        efiDeviceHandle = "HD0b";
        sortKey = "z_windows";
      };
    };
  };

  # LTS kernel: ZFS is an out-of-tree module and lags new kernel releases.
  # A newer kernel is fine only while
  #   nix eval .#nixosConfigurations.darkhero.pkgs.<kernelPackages>.${pkgs.zfs.kernelModuleAttribute}.meta.broken
  # prints false.
  boot.kernelPackages = pkgs.linuxPackages;

  # Render a panic as a QR code of the kernel log. amdgpu registers with the
  # drm panic handler, so this works from inside a Wayland session.
  boot.kernelParams = [ "drm.panic_screen=qr_code" ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.sops.yaml;
    # SSH key bind mount from impermanence happens after neededForUsers secrets run.
    # Use a dedicated age key on /persist (mounted in stage-1, always available).
    age.sshKeyPaths = [];
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";
    age.generateKey = false;
  };

  system.stateVersion = "26.05";
}
