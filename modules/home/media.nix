{ config, pkgs, ... }: {
  home.packages = with pkgs; [
    spotify
    vlc
    ffmpeg
    yt-dlp
    imagemagick
    calibre
    transmission-gtk
  ];
}
