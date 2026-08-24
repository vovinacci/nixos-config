{ config, pkgs, nix-index-database, sops-nix, username, ... }: {
  imports = [
    ../modules/system/audio.nix
    ../modules/system/desktop.nix
    ../modules/system/docker.nix
    ../modules/system/gaming.nix
    ../modules/system/gpu.nix
    ../modules/system/input.nix
    ../modules/system/keymap.nix
    ../modules/system/networking.nix
    ../modules/system/bluetooth.nix
    ../modules/system/memory-tools.nix
  ];

  home-manager = {
    useGlobalPkgs   = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit nix-index-database sops-nix username; };
    users.${username} = import ../home/workstation.nix;
  };

  sops.secrets.user_password_hash = {
    neededForUsers = true;
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "input" "audio" "docker" "cdrom" "i2c" ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.user_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKYoT6GSNhgTxsacAnoRUZk6pXHSjen7PMf/goq2qJB"
    ];
  };
}
