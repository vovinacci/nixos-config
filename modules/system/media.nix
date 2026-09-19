{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    spotify
    vlc
    imv
    ffmpeg
    yt-dlp
    imagemagick
    calibre
    transmission_4-gtk
  ];
}
