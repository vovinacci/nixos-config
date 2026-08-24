# NixOS Fleet Configuration

Flake-based NixOS configuration for the `darkhero` workstation. Manages system and
home-manager configuration declaratively with ephemeral root and SOPS-encrypted secrets.

## Repository Layout

```
flake.nix        - inputs, host definitions, mkSystem helper
flake.lock       - locked dependency versions
hosts/           - per-host hardware, boot, and impermanence config
modules/system/  - NixOS system modules (hardware, services, OS packages)
modules/home/    - home-manager modules (dotfiles, user applications)
profiles/        - module collections wired together per use-case
home/            - per-user home-manager entrypoints
secrets/         - SOPS-encrypted secrets (*.sops.yaml)
docs/            - operational documentation
```

## Hosts

| Host     | Role                | Architecture  |
|----------|---------------------|---------------|
| darkhero | Primary workstation | x86\_64-linux |

## Architecture Notes

- **Ephemeral root**: `/` is a 4 GB tmpfs. Only `/nix`, `/home`, and `/persist` survive
  reboots (Btrfs subvolumes). System state listed in `hosts/darkhero/impermanence.nix`
  is bind-mounted from `/persist`.
- **Secrets**: SOPS/age with a three-key model - host age key (boot-time), user age key
  (session), and YubiKey (interactive editing). See [Security](docs/security.md).
- **Nixpkgs channel**: tracks `nixos-unstable`.

## Quick Start

Rebuild and switch (`nh` wraps `nixos-rebuild` and handles privilege elevation
itself, so no `sudo`):

```shell
nh os switch
```

`programs.nh.flake` exports `NH_FLAKE=/etc/nixos`, so no path argument is needed,
and nh defaults the host to the current hostname. Add `-u` when you also want to
bump every flake input. Build without activating:

```shell
nh os build
```

Test in a VM before switching:

```shell
nh os build-vm
./result/bin/run-darkhero-vm
```

## Further Reading

- [Contributing](CONTRIBUTING.md) - making changes, testing, commit conventions
- [Operations](docs/operations.md) - updates, rollbacks, adding hosts, test VMs
- [Security](docs/security.md) - secrets management, YubiKey, key rotation
