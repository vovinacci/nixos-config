{ config, pkgs, ... }: {
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
    # Root SSD (Transcend ESD310C, 2174:2100) is a USB device on UAS, behind an
    # ASMedia ASM1074 hub. UAS link resets corrupt the FS. Force BOT (disable
    # UAS) for this bridge to test stability before the XFS migration.
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

  system.stateVersion = "26.05";
}
