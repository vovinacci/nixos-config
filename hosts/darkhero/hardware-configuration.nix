{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "uas"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/ab90ea6e-7f56-468e-8442-2b3a08cf716a";
    fsType = "btrfs";
    options = [ "subvol=@nix" "noatime" "compress=zstd" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/ab90ea6e-7f56-468e-8442-2b3a08cf716a";
    fsType = "btrfs";
    options = [ "subvol=@home" "noatime" "compress=zstd" ];
    neededForBoot = true;
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/ab90ea6e-7f56-468e-8442-2b3a08cf716a";
    fsType = "btrfs";
    options = [ "subvol=@persist" "noatime" "compress=zstd" ];
    neededForBoot = true;
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/0A91-60C7";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [{ device = "/dev/disk/by-uuid/adf12abd-93d3-48ad-bb1b-103d57cdcbdd"; }];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = true;
}
