# MPD daemon + Cantata frontend
# MPD runs as a user service (systemd --user), outputting audio through PipeWire
{pkgs, ...}: {
  services.mpd = {
    enable = true;
    musicDirectory = "/home/zhaochanglong/Music";
    network.listenAddress = "127.0.0.1";
    network.startWhenNeeded = true;
    extraConfig = ''
      audio_output {
        type "pulse"
        name "PipeWire Output"
      }

      # Audio buffer in seconds; keep it generous to avoid stuttering
      audio_buffer_size "4096"
      buffer_before_play "20%"

      # Use the high-quality soxr resampler (only active when playing regular CD-quality sources)
      samplerate_converter "soxr"
    '';
  };

  home.packages = with pkgs; [
    mpc # command-line control
    cantata # graphical MPD frontend
  ];
}
