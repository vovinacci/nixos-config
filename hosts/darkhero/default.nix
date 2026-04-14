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
    systemd-boot.enable = true;
  };


  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.extraModulePackages = [ config.boot.kernelPackages.vhba ];
  boot.kernelModules = [ "vhba" ];
  boot.kernelParams = [ 
    "rootdelay=20"
    "usbcore.autosuspend=-1"
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
