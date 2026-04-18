{ config, pkgs, ... }: {
  systemd.user.services.clipboard-trim = {
    Unit.Description = "Strip trailing spaces from clipboard selections";
    Service.ExecStart = pkgs.writeShellScript "clipboard-trim" ''
      ${pkgs.wl-clipboard}/bin/wl-paste --watch --no-newline sh -c \
        'printf "%s" "$(${pkgs.wl-clipboard}/bin/wl-paste --no-newline | sed "s/ *$//")" | ${pkgs.wl-clipboard}/bin/wl-copy'
    '';
    Service.Restart = "on-failure";
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        font             = "JetBrainsMono Nerd Font:size=12";
        pad              = "12x12";
        selection-target = "both";
      };
      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}
