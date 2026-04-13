{ config, pkgs, ... }: {
  imports = [
    ../modules/system/audio.nix
    ../modules/system/desktop.nix
    ../modules/system/gpu.nix
    ../modules/system/networking.nix
    ../modules/system/bluetooth.nix
  ];

  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    users.vovin = import ../home/workstation.nix;
  };

  users.users.vovin = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "input" "audio" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKYoT6GSNhgTxsacAnoRUZk6pXHSjen7PMf/goq2qJB vovin@iKOCMOC14-3.local"
    ];
  };
}
