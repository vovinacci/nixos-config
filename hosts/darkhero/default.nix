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
  boot.kernelParams = [ 
    "rootdelay=20"
    "usbcore.autosuspend=-1"
  ];
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  system.stateVersion = "26.05";
}
