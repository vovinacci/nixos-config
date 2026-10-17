{ config, pkgs, ... }: {
  virtualisation.docker = {
    enable = true;
    # Socket-activated on first use rather than started at boot: starting at
    # boot puts NetworkManager-wait-online on the boot critical path.
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
