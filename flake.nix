{
  description = "darkhero fleet config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    impermanence,
    nix-index-database,
    sops-nix,
    ...
  }:
  let
    mkSystem = { system, hostname, username, profiles ? [] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit impermanence sops-nix nix-index-database username;
          pkgs-stable = nixpkgs-stable.legacyPackages.${system};
        };
        modules = [
          {
            # TODO: remove these overrides as upstream fixes land on unstable
            nixpkgs.overlays = [
              (final: prev: {
                # Broken test_style_output tests with python3.13 (blocks pgcli)
                python3Packages = prev.python3Packages.overrideScope (pyFinal: pyPrev: {
                  cli-helpers = pyPrev.cli-helpers.overridePythonAttrs {
                    doCheck = false;
                  };
                });
                # Flaky syncreplication test (blocks lutris)
                openldap = prev.openldap.overrideAttrs {
                  doCheck = false;
                };
                # vhba 20250329 fails on kernel >=6.11 (queuecommand signature change)
                linuxPackages_zen = prev.linuxPackages_zen.extend (lpFinal: lpPrev: {
                  vhba = lpPrev.vhba.overrideAttrs (_: rec {
                    version = "20260313";
                    src = prev.fetchurl {
                      url = "mirror://sourceforge/cdemu/vhba-module-${version}.tar.xz";
                      hash = "sha256-KTADv12dwrOG2w0F9ZXFVINVpTXW38Bv03n9mLsZAXQ=";
                    };
                  });
                });
              })
            ];
          }
          ./hosts/${hostname}/default.nix
          ./modules/system/common.nix
          impermanence.nixosModules.impermanence
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
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
