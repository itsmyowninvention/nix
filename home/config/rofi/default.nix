_: {
  xdg.configFile = {
    "rofi/config.rasi".source = ./content/config.rasi;
    # matugen: Material You colors extracted from the active wallpaper
    # (template + config are read-only inputs; output lands in ~/.cache/rofi)
    "rofi/matugen/rofi-colors.rasi".source = ./content/rofi-colors.rasi;
    "rofi/matugen/config.toml".source = ./content/matugen-config.toml;
    "rofi/powermenu.rasi".source = ./content/powermenu.rasi;
    "rofi/launcher.sh" = {
      source = ./content/launcher.sh;
      executable = true;
    };
    "rofi/powermenu.sh" = {
      source = ./content/powermenu.sh;
      executable = true;
    };
  };
}
