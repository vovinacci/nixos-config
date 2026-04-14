{ config, pkgs, pkgs-stable, nix-index-database, sops-nix, ... }: {
  imports = [
    ../modules/system/audio.nix
    ../modules/system/desktop.nix
    ../modules/system/docker.nix
    ../modules/system/gpu.nix
    ../modules/system/input.nix
    ../modules/system/networking.nix
    ../modules/system/bluetooth.nix
  ];

  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit pkgs-stable nix-index-database sops-nix; };
    users.vovin = import ../home/workstation.nix;
  };

  sops.secrets.user_password_hash = {
    neededForUsers = true;
  };

  users.users.vovin = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "input" "audio" "docker" ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.user_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKYoT6GSNhgTxsacAnoRUZk6pXHSjen7PMf/goq2qJB vovin@iKOCMOC14-3.local"
    ];
  };
}
