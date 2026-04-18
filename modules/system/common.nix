{ config, pkgs, ... }: {
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "vovin" "@wheel" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # wrap nixos-rebuild to avoid HOME ownership warning
  environment.shellAliases = {
    nixos-rebuild = "sudo env HOME=/root /run/current-system/sw/bin/nixos-rebuild";
  };

  environment.systemPackages = with pkgs; [
    git curl wget neovim
    ripgrep fd bat bat-extras.batman eza fzf htop btop
    pciutils usbutils
    cdemu-client cdemu-daemon
    pulseaudio
    blueman
    yubikey-manager
    yubikey-personalization
    pcsc-tools
  ];

  programs.nix-ld.enable = true;

  services.fwupd.enable = true;

  services.pcscd.enable = true;
  systemd.services.pcscd.restartIfChanged = false;

  hardware.enableRedistributableFirmware = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = false;
  security.sudo.extraConfig = ''
    Defaults env_keep += "HOME EDITOR VISUAL"
  '';

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    useXkbConfig = true;
  };

  services.xserver.xkb = {
    layout  = "us,ua";
    options = "grp:ctrl_space_toggle,compose:ralt";
  };
}
