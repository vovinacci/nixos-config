# Agent Instructions

Flake-based NixOS fleet configuration. `flake.nix` declares hosts through the
`mkSystem` helper; today exactly one is defined, `darkhero`, but the layout is
multi-host by design. Treat `flake.nix`, `profiles/`, and `modules/` as shared
fleet infrastructure, not as darkhero's private configuration - anything that
only makes sense on this machine belongs in `hosts/darkhero/`. The concrete
`darkhero` references below are the current host, not the only possible one.

This file covers only what is **different for an automated agent**. The repo's
conventions are documented once, for humans and agents alike, and are not
repeated here:

| You need                                            | Read                 |
|-----------------------------------------------------|----------------------|
| What this repo is, repository layout, host table     | `README.md`          |
| Change workflow, module conventions, workarounds, theme, commit format | `CONTRIBUTING.md`    |
| Update, rollback, garbage collection, adding a host | `docs/operations.md` |
| Secrets, keys, rotation                             | `docs/security.md`   |

**Read `CONTRIBUTING.md` before your first change to this repo.** In particular
"System vs Home" (one layer owns each package) and "Workarounds" - those two
cover the defects agents introduce here most often.

## Never Apply Changes Yourself

The operator drives this system with [`nh`](https://github.com/nix-community/nh).
`nh os switch`, `nh os test`, `nh os boot`, and `nh clean` all mutate the live
system, and `nh os switch -u` also rewrites `flake.lock`.

**Never run any of them on your own initiative.** Propose the command and let the
operator run it. This holds even when the change is small and even when a previous
command in the same session was approved.

## Verify by Evaluating, Not by Switching

```shell
nix eval --raw .#nixosConfigurations.darkhero.config.system.build.toplevel.drvPath
```

This evaluates the whole configuration - system *and* home-manager - without
touching the running system. It must print a `.drv` path and emit no
`evaluation warning:` lines (deprecated options, removed packages) before you
claim a change works.

`nh os build` goes further and actually builds, catching failures evaluation
cannot. It is safe - it activates nothing - but it is slow, so propose it rather
than running it unprompted on every edit.

Useful narrower checks:

```shell
# did the option actually take effect?
nix eval .#nixosConfigurations.darkhero.config.programs.solaar.enable

# what is really in each layer?
nix eval --json .#nixosConfigurations.darkhero.config.environment.systemPackages \
  --apply 'ps: map (p: p.name or "?") ps'
```

For anything touching boot, filesystems, or impermanence, propose a VM build
(`nh os build-vm`) and say so in your report.

## Report Honestly

State what you verified and how. If evaluation still warns, say so and quote the
warning. If a change needs a reboot or a re-login before it can be observed - an
impermanence entry, a systemd unit, a session variable - say that explicitly
rather than reporting the work as confirmed.

## Do Not Touch

- `flake.lock` by hand - it is produced by `nh os switch -u` / `nix flake update`
- `hosts/darkhero/hardware-configuration.nix` - generated, see CONTRIBUTING.md
- `secrets/*.sops.yaml` - encrypted; never write plaintext secrets anywhere in
  this tree, see `docs/security.md`
- `.omc/` - agent scratch state, gitignored

## Commits

Follow the format in `CONTRIBUTING.md`. Do not commit unless asked.
