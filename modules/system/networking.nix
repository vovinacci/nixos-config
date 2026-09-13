{ config, pkgs, ... }: {
  networking = {
    networkmanager.enable = true;
    # Port 22 is opened by services.openssh.openFirewall (default true).
    firewall.enable = true;
  };

  # Live capture as the user: setcap dumpcap wrapper for the wireshark group
  # (the user is added in profiles/workstation.nix). GUI build, not the default
  # wireshark-cli.
  programs.wireshark = {
    enable  = true;
    package = pkgs.wireshark;
  };
}
