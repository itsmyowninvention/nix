{
  self,
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./git.nix
    ./ssh.nix
    ./tmux
    ./zsh.nix
    ./direnv.nix
    ./codex.nix
    ./uv.nix
    ./helix.nix
    ./nixvim
    ./zed.nix
    ./kitty.nix
    ./config
    ./mpd.nix
    ./1password.nix
    ./appimage.nix
    ./podman
  ];

  home = {
    username = "zhaochanglong";
    homeDirectory = "/home/zhaochanglong";
    stateVersion = "24.05";
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  services.linux-wallpaperengine = {
    enable = true;
    assetsPath = config.home.homeDirectory + "/.local/share/Steam/steamapps/workshop/content/431960";
    wallpapers = [
      {
        monitor = "DP-3"; # monitor name
        wallpaperId = "3621295352";
      }
    ];
  };

  # linux-wallpaperengine ignores SIGTERM; on shutdown systemd would wait the full 90s timeout before SIGKILL;
  # SIGINT exits immediately in testing, so send SIGINT instead, keeping a 10s fallback timeout.
  systemd.user.services.linux-wallpaperengine.Service = {
    KillSignal = "SIGINT";
    TimeoutStopSec = "10s";
  };

  programs.ghostty = {
    enable = true;
    settings = {
      font-size = 18;
      font-family = "Hack Nerd Font";
      window-decoration = true;
      confirm-close-surface = false;
      maximize = true;
    };
  };

  programs.plasma = {
    enable = true;
    hotkeys.commands = {
      "launch-ghostty" = {
        name = "Launch Ghostty";
        key = "Ctrl+Alt+T";
        command = "ghostty";
      };
    };
    # Lock screen configuration
    kscreenlocker = {
      lockOnResume = true;
      timeout = 5; # lock the screen after 5 minutes of inactivity
    };
  };
}
