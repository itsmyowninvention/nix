{pkgs, ...}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  environment.systemPackages = with pkgs; [
    hyprlauncher
    hyprlock
    hypridle
    waybar
    rofi
    matugen # Material You colors for the rofi launcher (from the wallpaper)
    grim
    slurp
    wl-clipboard
    cliphist
    swayosd
  ];
}
