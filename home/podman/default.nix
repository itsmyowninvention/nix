_: {
  imports = [
    ./maibot.nix
    ./newapi.nix
    ./openlist.nix
  ];

  services.podman.enable = true;
}
