{
  description = "darkhero fleet config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    impermanence,
    nix-index-database,
    sops-nix,
    xremap,
    ...
  }:
  let
    mkSystem = { system, hostname, username, profiles ? [] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit impermanence sops-nix nix-index-database username;
        };
        modules = [
          ./hosts/${hostname}/default.nix
          ./modules/system/common.nix
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          xremap.nixosModules.default
        ] ++ profiles;
      };
  in {
    nixosConfigurations = {
      darkhero = mkSystem {
        system   = "x86_64-linux";
        hostname = "darkhero";
        username = "vovin";
        profiles = [ ./profiles/workstation.nix ];
      };
    };
  };
}
