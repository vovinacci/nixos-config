{ config, pkgs, ... }: {
  virtualisation.docker = {
    enable = true;
    # Socket-activated on first use instead of started at boot, which kept
    # NetworkManager-wait-online on the boot critical path.
    enableOnBoot = false;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

  environment.systemPackages = with pkgs; [
    docker-compose
    dive
    lazydocker
  ];
}
