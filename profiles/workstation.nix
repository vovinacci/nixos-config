{ config, username, ... }: {
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
    ../modules/system/shell.nix
    ../modules/system/dev.nix
    ../modules/system/apps.nix
    ../modules/system/media.nix
    ../modules/system/sway-scripts.nix
  ];

  sops.secrets.user_password_hash = {
    neededForUsers = true;
  };

  # Root gets the same password as the user. `/` is tmpfs and root has no
  # password otherwise, so /etc/shadow is rebuilt with root locked on every
  # boot and sulogin refuses the emergency shell - the only place to recover
  # from a failed mount (e.g. `zfs load-key` for /home).
  users.users.root.hashedPasswordFile = config.sops.secrets.user_password_hash.path;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "video" "input" "audio" "docker" "cdrom" "i2c" "wireshark" ];
    hashedPasswordFile = config.sops.secrets.user_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKYoT6GSNhgTxsacAnoRUZk6pXHSjen7PMf/goq2qJB"
    ];
  };
}
