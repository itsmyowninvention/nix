{
  self,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./overlays
    ./zram.nix
    ./packages
    ./home
    ./sops.nix
    ./sshd.nix
    ./firewall.nix
  ];

  networking = {
    networkmanager.enable = true;
    timeServers = [
      "ntp.aliyun.com"
      "ntp.tuna.tsinghua.edu.cn"
      "0.nixos.pool.ntp.org"
    ];
  };

  time.timeZone = "Asia/Shanghai";

  services = {
    xserver.enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    power-profiles-daemon.enable = true; # enable power profile switching
    logind.settings.Login = {
      IdleAction = "ignore"; # disable idle actions (no poweroff, no suspend, no hibernate)
      HandlePowerKey = "suspend"; # suspend when the power button is pressed
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    blueman.enable = true;
  };

  # Enable PipeWire
  security.rtkit.enable = true;

  powerManagement.cpuFreqGovernor = "performance"; # force the CPU governor to performance

  # Fonts configuration
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = ["Noto Color Emoji"];
      monospace = [
        "Sarasa Mono SC"
        "Noto Sans Mono CJK SC"
      ];
      sansSerif = [
        "Sarasa Term SC"
        "Noto Sans CJK SC"
      ];
      serif = ["Noto Serif CJK CJK"];
    };
    antialias = true;
    hinting.enable = true;
    subpixel.lcdfilter = "default";
  };

  fonts.packages = with pkgs; [
    wqy_microhei
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    sarasa-gothic
    corefonts
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    nerd-fonts.hack
    nerd-fonts.noto
  ];

  # Input Method
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-rime
      qt6Packages.fcitx5-configtool
      fcitx5-gtk
      fcitx5-material-color
    ];
  };

  programs.zsh.enable = true;
  programs._1password.enable = true;

  environment.variables = {
    GTK_IM_MODULE = lib.mkForce "";
    QT_IM_MODULE = lib.mkForce "";
  };

  # Define a user account.
  users.users.zhaochanglong = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "dialout"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5M2RGhIG1CslAdzx+1xcOFiAgJhw0FKFqhe/Wkm1qZ"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    channel.enable = false;
    gc = {
      automatic = true;
      persistent = true;
      dates = "02:00";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
    package = pkgs.lixPackageSets.stable.lix;
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Own cachix cache first: CI pushes every path cache.nixos.org
      # doesn't already serve (see .github/workflows/ci.yml). The NixOS
      # default (cache.nixos.org) is appended after by nixpkgs' mkAfter.
      substituters = [
        "https://itsmyowninvention.cachix.org"
      ];
      trusted-public-keys = [
        "itsmyowninvention.cachix.org-1:2jQNzmiDJrru2Z8gMKUYzCE7DOzu8MHD8j3gHGbDqcM="
      ];
    };
  };

  system.stateVersion = "25.11";
}
