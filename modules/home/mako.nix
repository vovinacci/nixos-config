{ config, ... }: {
  services.mako = {
    enable = true;
    settings = {
      default-timeout   = 5000;
      ignore-timeout    = false;
      layer             = "overlay";
      anchor            = "top-right";
      margin            = "8";
      padding           = "12";
      border-radius     = 6;
      border-size       = 1;
      background-color  = "#1a1a2eee";
      text-color        = "#cdd6f4";
      border-color      = "#313244";
    };
  };
}
