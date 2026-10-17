# Cheat Sheet

Everyday commands on `darkhero`. The other documents explain the why; this page
is only the what.

## Rebuild and Update

```shell
nh os switch               # apply /etc/nixos (no sudo, no path)
nh os switch -u            # update all flake inputs and apply; commit flake.lock afterwards
nh os test                 # activate now, keep the current boot default
nh os boot                 # make it the boot default, activate on next boot
nh os build                # build only, activate nothing
```

Quick check before building - must print a `.drv` path and no `evaluation warning:`:

```shell
nix eval --raw .#nixosConfigurations.darkhero.config.system.build.toplevel.drvPath
```

## Generations and Rollback

```shell
nh os info                 # list generations
nh os rollback             # back to the previous generation
nh clean all --keep 10     # what the weekly timer runs
```

Or pick an older entry in the systemd-boot menu. See [Operations](operations.md#rollback).

## Finding Software

```shell
, cowsay                   # run a program without installing it (comma)
nix shell nixpkgs#htop     # temporary shell with a package
nix-locate bin/ffprobe     # which package ships a file
nh search ripgrep          # search nixpkgs
```

## Health

```shell
systemctl --failed; systemctl --user --failed
journalctl -b -p 3         # errors since boot
zpool status -x            # "all pools are healthy"
zpool status               # scrub progress and last result
zfs list -o name,used,avail,mountpoint
sudo smartctl -H /dev/sda  # disk health; -l selftest for the self-test log
```

## Disk Unlock

```shell
KS=/dev/disk/by-partlabel/darkhero-keystore
sudo systemd-cryptenroll $KS    # enrolled slots
```

If the boot asks for the YubiKey PIN instead of unlocking silently (typically
after a firmware change), re-enroll the TPM:

```shell
sudo systemd-cryptenroll --unlock-fido2-device=auto \
  --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 $KS
```

See [Storage](storage.md#keystore).

## Secrets

```shell
sops secrets/secrets.sops.yaml  # system secrets, from /etc/nixos
```

User secrets are edited in the dotfiles repository. See [Security](security.md).

## Dotfiles

```shell
chezmoi diff               # live files vs. source
chezmoi apply              # source -> $HOME
chezmoi re-add <file>      # live edit -> source
```

## Firmware and Windows

```shell
systemctl reboot --firmware-setup   # reboot straight into the firmware setup
```

Windows is the last entry in the boot menu. If it disappears after a disk
change, re-check the EFI shell handle
([Operations](operations.md#dual-boot-with-windows)); the firmware boot menu
reaches Windows Boot Manager regardless.

## Desktop

`$mod+/` lists every sway key binding with its description, searchable; Enter
runs the selected one.
