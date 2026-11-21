{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    spotify
    vlc
    # mpris: waybar mpris module and media keys see mpv (VLC has it built in).
    (mpv.override { scripts = [ mpvScripts.mpris ]; })
    imv
    ffmpeg
    yt-dlp
    imagemagick
    calibre
    transmission_4-gtk
  ];
}
