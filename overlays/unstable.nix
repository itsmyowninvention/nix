# Pure overlay: lift selected packages from nixpkgs-unstable onto pkgs.
inputs: final: prev: let
  unstable = import inputs.nixpkgs-unstable {
    system = prev.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
      # enable on demand if an unstable package turns out to need it
      # allowUnfreePredicate = ...;
    };
  };
in {
  # only inherit packages missing from 26.05, or whose stable version is too outdated and must come from unstable
  inherit
    (unstable)
    code-cursor
    cursor-cli
    qbittorrent-enhanced
    qq
    podman-desktop
    intiface-central
    zed-editor
    pi-coding-agent
    wivrn
    steam
    proton-ge-bin
    monado
    ;
}
