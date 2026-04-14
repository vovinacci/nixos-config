{ config, pkgs, ... }: {
  systemd.user.services.cdemu-daemon = {
    Unit.Description = "CDEmu daemon";
    Service = {
      Type = "dbus";
      BusName = "net.sf.cdemu.CDEmuDaemon";
      ExecStart = "${pkgs.cdemu-daemon}/bin/cdemu-daemon --config-file %h/.config/cdemu-daemon";
      Restart = "no";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.packages = with pkgs; [
    zip
    unzip
    p7zip
    playerctl
    pavucontrol
    slack
    signal-desktop
    telegram-desktop
    wasistlos
    zoom-us
    teams-for-linux
    vscode
  ];
}
