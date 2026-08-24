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
cover the defects agents introduce here most often. For anything non-trivial,
model the change before solving it - see Model-First Reasoning below.

## Model-First Reasoning (MFR)

For any non-trivial change, work in two phases and **surface Phase 1 before
starting Phase 2**. Based on Kumar & Rana, *Model-First Reasoning LLM Agents:
Reducing Hallucinations through Explicit Problem Modeling*
(<https://arxiv.org/html/2512.14474v1>).

**Non-trivial** means any of: touching more than one module; changing boot,
filesystems, impermanence, secrets, or flake inputs; adding or removing a
package or service; or anything whose effect you cannot demonstrate with a
single `nix eval`. Single-file comment fixes, typos, and reordering within one
attribute set are trivial - just do them.

### Phase 1 - build the model. Produce no solution.

State, for this change only:

- **Entities** - the hosts, profiles, modules, options, packages, services,
  units, persistence entries, flake inputs, and secrets involved.
- **State variables** - what is true now and could change. Which layer owns a
  package. Whether an option is already set, and by whom: this repo, or an
  upstream module such as `programs.sway`. What is persisted versus on tmpfs.
  What is *running* versus what is *configured* - they differ until a switch,
  and for some changes until a reboot or re-login.
- **Actions, with preconditions and effects** - `nix eval` has no precondition
  and no system effect. `nh os build` builds but activates nothing. `nh os
  switch` and `nh clean` mutate the live system and are the operator's to run,
  never yours. `nix flake lock` rewrites `flake.lock`. Adding an impermanence
  entry only proves itself after a reboot.
- **Constraints** - the rules in `CONTRIBUTING.md`, plus anything specific to
  this change. Name the ones that actually bind here.
- **Unknowns** - what you have not verified yet, and how you intend to verify
  it. Prefer reading the module source under `/nix/store/*-source/` or
  evaluating an option over assuming.

Do not write edits, diffs, or commands during Phase 1. The separation is the
point: it is what stops a plausible-sounding fix from being built on an
unexamined assumption.

### Phase 2 - solve using only the model

Every action must respect a precondition you listed, every effect must be one
you predicted, and every constraint must still hold at the end. If you discover
mid-solve that the model was wrong, **return to Phase 1 and correct it** rather
than patching around it - a wrong model that gets patched produces exactly the
confident, wrong answer this is meant to prevent.

### Worked example

A change to waybar's stylesheet in this repo shipped a defect because Phase 1
was skipped. The model would have had to record that a focused sway workspace
carries **both** the `.focused` and `.visible` classes (a state variable), and
that equal-specificity CSS rules resolve by source order (a constraint). Neither
was written down, `.visible` was placed after `.focused`, and it repainted the
focused label to an unreadable light-grey on light-blue. Stating the two facts
first would have made the ordering requirement obvious before a line was written.

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
