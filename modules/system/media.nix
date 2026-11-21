{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    spotify
    vlc
    mpv
    imv
    ffmpeg
    yt-dlp
    imagemagick
    calibre
    transmission_4-gtk
  ];
}
