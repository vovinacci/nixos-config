{ config, pkgs, ... }: {
  imports = [
    ../modules/home/common.nix
    ../modules/home/neovim.nix
    ../modules/home/sway.nix
    ../modules/home/foot.nix
    ../modules/home/firefox.nix
    ../modules/home/dev.nix
    ../modules/home/fonts.nix
    ../modules/home/media.nix
    ../modules/home/apps.nix
    ../modules/home/gaming.nix
  ];

  home.username      = "vovin";
  home.homeDirectory = "/home/vovin";
  home.stateVersion  = "26.05";

  home.persistence."/persist" = {
    directories = [
      # data — always persist
      "Downloads"
      "Documents"
      "src"

      # credentials — must persist
      ".gnupg"
      ".kube"
      ".ssh"

      # app state — impractical to declare
      ".mozilla"                # firefox profile
      ".config/slack"           # slack state
      ".config/Signal"          # signal keys+messages
      ".config/spotify"         # spotify state
      ".config/zoom"            # zoom state
      ".config/teams-for-linux" # teams
      ".config/mc"              # your personal mc tweaks
      ".local/share/mc"

      # game data
      ".local/share/Steam"
      ".steam"
      ".config/heroic"          # GOG/Epic game library
      ".local/share/lutris"     # lutris game data

      # tooling state
      ".local/share/direnv"     # direnv cache
      ".config/git"
    ];

    files = [
      ".zsh_history"            # history is data, not config
    ];
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    history = {
      size = 100000;
      ignoreDups = true;
      share = true;
    };
  };

  home.packages = with pkgs; [
    jetbrains.idea
  ];
}
