{
  pkgs,
  inputs,
  ...
}: let
  # nixpkgs-unstable 实例：nipaplay 需要 flutter347 (26.05 只有 3.41)
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
  nipaplay-reload = unstable.callPackage ./nipaplay {
    nixpkgsPath = unstable.path;
  };
  claude-desktop = pkgs.callPackage ./claude-desktop.nix {};
  codegraph = pkgs.callPackage ./codegraph.nix {};
  oh-my-pi = pkgs.callPackage ./oh-my-pi.nix {};
  # OpenCode v2: 官方 flake 源码构建 (github:anomalyco/opencode @ v2.0.27)
  opencode-v2 = inputs.opencode.packages.${pkgs.system}.opencode;
in {
  imports = [
    ./flatpak.nix
    ./podman.nix
    ./hyprland.nix
    ./ccache.nix
    ./coolercontrol.nix
    ./wivrn.nix
    ./nix-ld.nix
    ./waydroid.nix
    ./incus.nix
  ];

  environment.systemPackages = with pkgs; [
    # Core CLI tools
    bubblewrap
    vim
    git
    gh
    tree
    wget
    htop
    aria2
    fd
    fzf
    ripgrep
    lazygit
    zoxide
    bat

    # Development
    gnumake
    gcc
    clang
    clang-tools
    cmake
    nodejs
    codegraph
    openspec
    pnpm
    metals
    gdb

    # System tools
    qemu
    nh
    ssh-to-age
    sops
    openssh

    # Nix tools
    nixd
    nil
    alejandra
    statix
    nom
    protontricks

    # Python tools
    ruff

    logisim-evolution
    yazi

    # Desktop apps
    vscodium
    code-cursor
    kdePackages.kate
    kdePackages.dolphin
    firefox
    alacritty
    obsidian
    telegram-desktop
    vlc
    celluloid
    haruna
    yt-dlp # Haruna 在线视频/缩略图依赖
    qbittorrent-enhanced
    qq
    protonup-qt
    pciutils
    mangohud
    ryubing # Switch 模拟器 (Ryujinx 社区 fork)
    netease-cloud-music-gtk
    unrar
    p7zip
    unar
    ppsspp-sdl-wayland
    appimage-run
    nipaplay-reload
    podman-desktop
    thunderbird
    chromium
    tor-browser
    discord
    gnome-network-displays
    drawio
    zotero
    valgrind
    obs-studio
    lm_sensors
    liquidctl # USB AIOs、水冷、风扇集线器支持
    intiface-central
    cursor-cli
    pi-coding-agent
    opencode-v2
    claude-desktop # 官方 Linux beta (apt 源打包, 见 packages/claude-desktop.nix)
    oh-my-pi
    marktext
    gittyup
    wl-clipboard
    cliphist
    jupyter-all
    gtkwave
    libreoffice-fresh # 办公套件，编辑 xlsx/docx
  ];

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["zhaochanglong"];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # 远程串流
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # 允许 Sunshine 捕获屏幕和模拟输入
    openFirewall = true; # 自动打开必要的端口 (47984-48010 等)
  };

  services.redshift.enable = true;
  location.provider = "geoclue2";
}
