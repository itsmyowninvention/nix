{
  description = "NixOS System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.7.0";

    plasma-manager = {
      url = "github:nix-community/plasma-manager"; # no release-26.05, use trunk
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixvim.url = "github:nix-community/nixvim/nixos-26.05";

    opencode = {
      url = "github:anomalyco/opencode/v2.0.27";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    specialArgs = {inherit inputs self;};
  in {
    # Formatter outputs for `nix fmt`
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    # Reusable overlays (pure final: prev functions)
    overlays = {
      unstable = import ./overlays/unstable.nix inputs;
      default = self.overlays.unstable;
    };

    nixosConfigurations."b850m" = nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ./hardware/b850m.nix
        {networking.hostName = "b850m";}
        ./.
      ];
    };

    nixosConfigurations."hades" = nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ./hardware/hades.nix
        {networking.hostName = "hades";}
        ./.
      ];
    };
  };
}
