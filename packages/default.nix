{
  pkgs,
  inputs,
  ...
}: let
  # nixpkgs-unstable instance: nipaplay needs flutter347 (26.05 only has 3.41)
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  nipaplay-reload = unstable.callPackage ./nipaplay {
    nixpkgsPath = unstable.path;
  };
  claude-desktop = pkgs.callPackage ./claude-desktop.nix {};
  codegraph = pkgs.callPackage ./codegraph.nix {};
  oh-my-pi = pkgs.callPackage ./oh-my-pi.nix {};
  # OpenCode v2: built from source via the official flake (github:anomalyco/opencode @ v2.0.27)
  opencode-v2 = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
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
    yt-dlp # needed by Haruna for online video/thumbnails
    qbittorrent-enhanced
    qq
    protonup-qt
    pciutils
    mangohud
    ryubing # Switch emulator (Ryujinx community fork)
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
    liquidctl # support for USB AIOs, liquid coolers, and fan hubs
    intiface-central
    cursor-cli
    pi-coding-agent
    opencode-v2
    claude-desktop # official Linux beta (packaged from the apt repo, see packages/claude-desktop.nix)
    oh-my-pi
    marktext
    gittyup
    wl-clipboard
    cliphist
    jupyter-all
    gtkwave
    libreoffice-fresh # office suite for editing xlsx/docx
  ];

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = ["zhaochanglong"];
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # remote play streaming
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # allow Sunshine to capture the screen and inject input
    openFirewall = true; # open the required ports automatically (47984-48010 etc.)
  };

  services.redshift.enable = true;
  location.provider = "geoclue2";
}
