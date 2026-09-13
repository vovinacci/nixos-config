{ config, pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Early KMS: amdgpu in the initrd also lets the drm panic handler render a
  # QR code for a panic during stage 1 (see drm.panic_screen in hosts/darkhero).
  hardware.amdgpu.initrd.enable = true;

  environment.systemPackages = with pkgs; [
    radeontop
    vulkan-tools
  ];
}
