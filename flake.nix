{
  description = "darkhero fleet config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      # impermanence's home-manager module is unused: user configuration is
      # not managed by this repo (see README).
      inputs.home-manager.follows = "";
    };

    # AI coding CLIs release far faster than nixpkgs; this flake tracks them
    # daily and carries packages nixpkgs lacks (cursor-agent, antigravity-cli).
    # Its packages expect unstable, so it follows nixpkgs-unstable, not the
    # system's nixpkgs.
    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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
    impermanence,
    nix-ai-tools,
    nix-index-database,
    sops-nix,
    xremap,
    ...
  }:
  let
    # The platform comes from each host's hardware-configuration.nix
    # (nixpkgs.hostPlatform); nixosSystem's `system` argument is legacy.
    mkSystem = { hostname, username, profiles ? [] }:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit sops-nix nix-index-database username;
        };
        modules = [
          {
            nixpkgs.overlays = [
              (final: prev: {
                ai-tools = nix-ai-tools.packages.${prev.stdenv.hostPlatform.system};
              })
            ];
          }
          ./hosts/${hostname}/default.nix
          ./modules/system/common.nix
          impermanence.nixosModules.impermanence
          nix-index-database.nixosModules.nix-index
          sops-nix.nixosModules.sops
          xremap.nixosModules.default
        ] ++ profiles;
      };
  in {
    nixosConfigurations = {
      darkhero = mkSystem {
        hostname = "darkhero";
        username = "vovin";
        profiles = [ ./profiles/workstation.nix ];
      };
    };
  };
}
