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
        monitor = "DP-3"; # 显示器名称
        wallpaperId = "3621295352";
      }
    ];
  };

  # linux-wallpaperengine 不响应 SIGTERM，关机时 systemd 要等满 90s 超时才 SIGKILL；
  # 实测 SIGINT 立即退出，故改发 SIGINT，并留 10s 兜底超时。
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
    # 锁屏配置
    kscreenlocker = {
      lockOnResume = true;
      timeout = 5; # 5分钟无操作后锁屏
    };
  };
}
