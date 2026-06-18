{ username, ... }: {
  hardware.uinput.enable = true;   # vovin is already in the "input" group

  services.xremap = {
    enable      = true;
    serviceMode = "user";    # user session so it can reach WAYLAND_DISPLAY for app detection
    userName    = username;
    withWlroots = true;      # Sway is wlroots-based; enables per-application remaps
    config.keymap = [
      {
        name = "terminals";
        application.only = [ "foot" "com.mitchellh.ghostty" ];  # footclient is app_id "foot"
        remap = { "SUPER-c" = "C-Shift-c"; "SUPER-v" = "C-Shift-v"; "SUPER-x" = "C-Shift-x"; };
      }
      {
        name = "macos-style editing";
        remap = { "SUPER-c" = "C-c"; "SUPER-v" = "C-v"; "SUPER-x" = "C-x"; };
      }
    ];
  };
}
