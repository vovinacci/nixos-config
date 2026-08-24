# Contributing

## Making a Change

1. **Edit** the relevant module under `modules/system/`, `modules/home/`, or a host
   file under `hosts/`.
2. **Evaluate** first - this is cheap and catches deprecated options and removed
   packages before you build anything:
   ```shell
   nix eval --raw .#nixosConfigurations.darkhero.config.system.build.toplevel.drvPath
   ```
   It must print a `.drv` path with no `evaluation warning:` lines.
3. **Test** in a VM before touching the live system:
   ```shell
   nh os build-vm
   ./result/bin/run-darkhero-vm
   ```
   The VM has no hardware-specific features (no YubiKey, no GPU passthrough, no real
   disk layout), but it is sufficient to catch syntax errors and basic runtime issues.
4. **Apply** to the live system:
   ```shell
   nh os switch
   ```
   `nh` elevates privileges itself - do not prefix it with `sudo`. No path or `-H` is
   needed; `programs.nh.flake` exports `NH_FLAKE=/etc/nixos` and nh defaults the host to
   the current hostname. Add `-u` when you also want to bump `flake.lock` - keep that a
   deliberate step rather than part of every rebuild. Use `nh os test` to activate
   without making the generation the boot default.
5. **Commit** once the system is working.

## Module Conventions

### System vs Home

| Concern                                       | Where             |
|-----------------------------------------------|-------------------|
| Hardware, kernel, daemons, system services    | `modules/system/` |
| User dotfiles, user applications, desktop env | `modules/home/`   |

**One layer owns each package.** The most common defect in this repo is the same
program installed twice - once in `environment.systemPackages` and once in
`home.packages`, or once as a package and once by the module that already installs
it. Before adding a package, grep for it across `modules/` and check whether an
option already provides it:

- `services.blueman.enable` installs `blueman`
- `programs.solaar.enable` installs `solaar`
- `programs.delta`, `programs.fzf`, `programs.waybar`, `programs.firefox`, and
  `programs.yazi` each install their own package

The system layer is for root-shell and rescue tooling (`git`, `curl`, `neovim`) and
for things with no home-manager equivalent. Anything configured through
`programs.*`/`services.*` in home-manager belongs to the home layer only. A package
that a module configures should be installed by that same module - see
`modules/home/wofi.nix`, which owns both the wofi package and its stylesheet.

### New Module vs Extending Existing

- **New module**: when the concern is self-contained and togglable (e.g. a new hardware
  device, a new application category). Create `modules/system/<name>.nix` or
  `modules/home/<name>.nix` and import it in the relevant profile or home entrypoint.
- **Extend existing**: when the change logically belongs to an existing module (e.g.
  adding a package to `dev.nix`, tweaking a keybinding in `sway.nix`).

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

### Host-Specific Configuration

Shared modules must not hardcode a particular machine - monitor names, refresh
rates, and geographic coordinates belong in `hosts/<name>/`.

Known outstanding violations. Do not add more; prefer fixing one if you are already
editing the file:

- `modules/home/sway.nix` pins output `DP-2` to `3840x2160@143.963Hz`
- `modules/home/sway.nix` passes Kyiv coordinates to `wlsunset`

### Generated Files

`hosts/<name>/hardware-configuration.nix` is produced by `nixos-generate-config` and
is effectively read-only - edits are lost the next time it is regenerated. Declare
kernel modules, filesystem options, and drivers in `modules/system/` or
`hosts/<name>/default.nix` instead. Where an exception exists it carries a comment
explaining what must not be re-added.

## Workarounds

A workaround in this repo states three things: *what is broken upstream*, *why this
fixes it*, and *when it can be removed*. Existing examples to follow:

- `hosts/darkhero/default.nix` - vhba udev rule, USB storage quirk
- `modules/home/common.nix` - `set-SSH_AUTH_SOCK` dependency cycle, atuin `?` rebind
- `modules/system/desktop.nix` - udisks polkit rule, FUSE `allow_other`

**Never delete a commented workaround because it looks obsolete.** Verify upstream
first: read the module source under `/nix/store/*-source/`, or run the tool and
inspect its output.

Two in the tree have been re-verified and are still required. Do not remove either
without repeating that check:

| Workaround | Why it still applies |
|------------|----------------------|
| `set-SSH_AUTH_SOCK.Unit.DefaultDependencies = false` | home-manager's `modules/misc/ssh-auth-sock.nix` still emits the cyclic ordering |
| `bindkey '?' self-insert` at `mkOrder 2500` | `atuin init zsh` still binds `?` to its AI prompt |

## Theme

Desktop surfaces (sway, waybar, swaync, wofi, swaylock) share one palette. Reuse
these values rather than inventing hex codes:

| Role          | Value     |
|---------------|-----------|
| base          | `#1a1a2e` |
| mantle        | `#181825` |
| surface0      | `#313244` |
| surface1      | `#45475a` |
| overlay0      | `#6c7086` |
| text          | `#cdd6f4` |
| subtext       | `#bac2de` |
| blue (accent) | `#89b4fa` |
| green         | `#a6e3a1` |
| peach         | `#fab387` |
| red           | `#f38ba8` |

Everything except `base` is stock Catppuccin Mocha. `#1a1a2e` is this repo's own
darker base, deliberately not Mocha's `#1e1e2e` - match the repo, not upstream
Catppuccin. `modules/home/waybar.nix` is the one surface still using waybar's
upstream stylesheet.

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description>
```

Common types: `feat`, `fix`, `refactor`, `docs`, `chore`, and `deps` - this repo's
own type for flake input bumps.

Examples:

```
feat: add gaming module with Steam and Heroic
fix: correct swaylock idle trigger
chore: update flake inputs
docs: document secrets rotation procedure
```

Keep the subject line under 72 characters. No trailing full stop.

### Body

The body is **optional, and most commits should not have one**. The diff already
shows what changed; a body exists to answer *why*, and only when the diff cannot.

Write one when:

- the reason is not visible in the diff - a change that looks like a no-op but
  fixes a silent bug, or a removal that looks risky but is not
- there is evidence worth recording: a quoted evaluation warning, an empty
  `nix store diff-closures`, a measurement behind a chosen number

Skip it when the subject plus the diff already tell the whole story. Renames,
package moves, doc rewrites, and comment fixes usually need nothing.

**Do not restate in the body what the same diff puts in a comment.** Comments
describe the state, commit messages describe the change, and they have different
lifespans: people read code, not `git log`. If a reason has to survive - "do not
delete this, here is what breaks" - it belongs in a comment next to the code. Put
it there, then keep the commit body short or omit it.

## What NOT to Put in This Repository

- **Plaintext secrets** of any kind - passwords, private keys, tokens, API keys.
  Encrypt with SOPS before committing. See [Security](docs/security.md).
- **SSH private keys** - the `ssh_bundle` secret in `secrets/ssh.sops.yaml` holds
  all SSH keys encrypted; the deploy service extracts them at login.
- **Personal data** - avoid embedding identifiable information (e.g. device names,
  email addresses) in config files. Keep such details in SOPS secrets where possible.
- **Unencrypted `.yaml` files** under `secrets/` - the `.gitignore` blocks `*.yaml`
  and only allows `*.sops.yaml`. Do not override this.
