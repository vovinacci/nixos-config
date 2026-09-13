{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    spotify
    vlc
    imv   # default image viewer, see xdg.mimeApps in gtk.nix
    ffmpeg
    yt-dlp
    imagemagick
    calibre
    transmission_4-gtk
  ];
}
