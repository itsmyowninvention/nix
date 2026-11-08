{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  # pi-acp: bridge between ACP (Agent Client Protocol) and `pi --mode rpc`.
  # agentic.nix resolves the bare command "pi-acp" from PATH (ACP subprocesses inherit that PATH).
  # The pi binary comes from the system package pi-coding-agent; the adapter only spawns it, no injection needed here.
  programs.nixvim.extraPackages = [
    (pkgs.callPackage ../../packages/pi-acp.nix {})
  ];

  programs.nixvim = {
    enable = true;

    # nixvim instantiates its own nixpkgs; system allowUnfree does not apply.
    nixpkgs.config.allowUnfree = true;

    imports = [
      ./config
    ];
  };
}
