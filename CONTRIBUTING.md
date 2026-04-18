# Contributing

## Making a Change

1. **Edit** the relevant module under `modules/system/`, `modules/home/`, or a host
   file under `hosts/`.
2. **Test** in a VM before touching the live system:
   ```shell
   nixos-rebuild build-vm --flake /etc/nixos#darkhero
   ./result/bin/run-darkhero-vm
   ```
   The VM has no hardware-specific features (no YubiKey, no GPU passthrough, no real
   disk layout), but it is sufficient to catch syntax errors and basic runtime issues.
3. **Apply** to the live system:
   ```shell
   nixos-rebuild switch --flake /etc/nixos#darkhero
   ```
   This uses the shell alias defined in `modules/system/common.nix`, which wraps the
   command with `sudo env HOME=/root` to avoid a HOME ownership warning from sudo.
4. **Commit** once the system is working.

## Module Conventions

### System vs Home

| Concern                                       | Where             |
|-----------------------------------------------|-------------------|
| Hardware, kernel, daemons, system services    | `modules/system/` |
| User dotfiles, user applications, desktop env | `modules/home/`   |

### New Module vs Extending Existing

- **New module**: when the concern is self-contained and togglable (e.g. a new hardware
  device, a new application category). Create `modules/system/<name>.nix` or
  `modules/home/<name>.nix` and import it in the relevant profile or home entrypoint.
- **Extend existing**: when the change logically belongs to an existing module (e.g.
  adding a package to `dev.nix`, tweaking a keybinding in `sway.nix`).

Avoid putting host-specific options in shared modules - those belong in `hosts/<name>/`.

### Wiring a New Module In

- **System module** - import in `profiles/workstation.nix` (or the relevant profile).
- **Home module** - import in `home/workstation.nix` (or the relevant home entrypoint).
- **Host-specific config** - import inside `hosts/<name>/default.nix`.

Example - adding a new system module:

```nix
# profiles/workstation.nix
imports = [
  ../modules/system/audio.nix
  ../modules/system/mynewmodule.nix  # add here
  ...
];
```

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description>
```

Common types: `feat`, `fix`, `refactor`, `docs`, `chore`.

Examples:

```
feat: add gaming module with Steam and Heroic
fix: correct swaylock idle trigger
chore: update flake inputs
docs: document secrets rotation procedure
```

Keep the subject line under 72 characters. No trailing full stop.

## What NOT to Put in This Repository

- **Plaintext secrets** of any kind - passwords, private keys, tokens, API keys.
  Encrypt with SOPS before committing. See [Security](docs/security.md).
- **SSH private keys** - the `ssh_bundle` secret in `secrets/ssh.sops.yaml` holds
  all SSH keys encrypted; the deploy service extracts them at login.
- **Personal data** - avoid embedding identifiable information (e.g. device names,
  email addresses) in config files. Keep such details in SOPS secrets where possible.
- **Unencrypted `.yaml` files** under `secrets/` - the `.gitignore` blocks `*.yaml`
  and only allows `*.sops.yaml`. Do not override this.
