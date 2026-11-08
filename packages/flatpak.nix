{inputs, ...}: {
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];
  services.flatpak = {
    enable = true;
    update.onActivation = true; # check for updates on every rebuild
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      "com.usebottles.bottles"
      "com.tencent.WeChat"
      "com.qq.QQmusic" # QQ Music (community-maintained package)
      "com.geeks3d.furmark"
      "io.github.hypengw.Qcm"
      "moe.launcher.an-anime-game-launcher" # Genshin Impact (AAGL)
      "com.baidu.NetDisk"
    ];
  };
}
