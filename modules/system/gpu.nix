{ config, pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.initrd.kernelModules = [ "amdgpu" ];

  environment.systemPackages = with pkgs; [
    radeontop
    vulkan-tools
  ];
}
