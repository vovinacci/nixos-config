{ username, ... }: {
  # User-mode xremap sets up uinput and adds the user to the input and uinput
  # groups itself.
  services.xremap = {
    enable      = true;
    serviceMode = "user";    # user session so it can reach WAYLAND_DISPLAY for app detection
    userName    = username;
    withWlroots = true;      # Sway is wlroots-based; enables per-application remaps
    watch       = true;      # also grab keyboards plugged in after login
    # exact_match: without it xremap still matches when extra modifiers are
    # held, so Super+Shift+C/V left as Ctrl+Shift+C/V and sway's $mod+Shift+c
    # (reload) and $mod+Shift+v (clipboard history) never fired.
    config.keymap = [
      {
        name = "terminals";
        exact_match = true;
        application.only = [ "com.mitchellh.ghostty" ];
        remap = { "SUPER-c" = "C-Shift-c"; "SUPER-v" = "C-Shift-v"; "SUPER-x" = "C-Shift-x"; };
      }
      {
        name = "macos-style editing";
        exact_match = true;
        remap = { "SUPER-c" = "C-c"; "SUPER-v" = "C-v"; "SUPER-x" = "C-x"; };
      }
    ];
  };
}
