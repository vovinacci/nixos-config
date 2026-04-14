{ config, pkgs, nix-index-database, sops-nix, ... }: {
  imports = [
    nix-index-database.homeModules.nix-index
    sops-nix.homeManagerModules.sops
    ../modules/home/common.nix
    ../modules/home/neovim.nix
    ../modules/home/sway.nix
    ../modules/home/waybar.nix
    ../modules/home/foot.nix
    ../modules/home/firefox.nix
    ../modules/home/dev.nix
    ../modules/home/fonts.nix
    ../modules/home/media.nix
    ../modules/home/apps.nix
    ../modules/home/gaming.nix
    ../modules/home/mako.nix
    ../modules/home/gtk.nix
    ../modules/home/wofi.nix
  ];

  home.username      = "vovin";
  home.homeDirectory = "/home/vovin";
  home.stateVersion  = "26.05";

  programs.nix-index-database.comma.enable = true;

  sops = {
    defaultSopsFile = ../secrets/secrets.sops.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets.git_user_config = {
      path = "${config.home.homeDirectory}/.config/git/user";
    };
    secrets.zsh_local = {
      path = "${config.home.homeDirectory}/.config/zsh/local.zsh";
    };
    secrets.ssh_bundle = {
      sopsFile = ../secrets/ssh.sops.yaml;
      mode     = "0700";
    };
  };

  systemd.user.services.ssh-bundle = {
    Unit = {
      Description = "Deploy SSH keys and config from SOPS bundle";
      After       = [ "sops-nix.service" ];
      Wants       = [ "sops-nix.service" ];
    };
    Service = {
      Type            = "oneshot";
      ExecStart       = "${pkgs.bash}/bin/bash ${config.sops.secrets.ssh_bundle.path}";
      RemainAfterExit = true;
      Environment     = "PATH=${pkgs.coreutils}/bin:${pkgs.bash}/bin";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.packages = with pkgs; [
    jetbrains.idea
  ];
}
