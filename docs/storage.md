# Storage

Disks, pools and encryption on `darkhero`. The configuration is
`hosts/darkhero/disks.nix`; this file explains it and covers the operations it
does not automate.

## Layout

| disk (by-id)                            | partition label     | size   | content                              |
|-----------------------------------------|---------------------|--------|--------------------------------------|
| `nvme-WDS100T1X0E-00AFY0_211417440503`  | `darkhero-esp`      | 2 GiB  | vfat, `/boot/efi`                    |
|                                         | `darkhero-keystore` | 64 MiB | LUKS2, ext4 holding the ZFS key files |
|                                         | `darkhero-swap`     | 16 GiB | swap, new random key every boot      |
|                                         | `darkhero-rpool`    | rest   | ZFS pool `rpool`                     |
| `ata-WDC_WD101EFBX-68B0AN0_VCJW40YP`    | `darkhero-tank`     | whole  | ZFS pool `tank`, one vdev            |
| `nvme-WDS200T1X0E-00AFY0_21383Q802934`  | -                   | 2 TB   | Windows, see [Operations](operations.md#dual-boot-with-windows) |

| dataset              | mount                  | notes                                      |
|----------------------|------------------------|--------------------------------------------|
| `rpool/local/nix`    | `/nix`                 | legacy mount, stage 1                      |
| `rpool/safe/persist` | `/persist`             | legacy mount, stage 1, unencrypted         |
| `rpool/safe/home`    | `/home`                | legacy mount, aes-256-gcm, hex key         |
| `rpool/reserved`     | -                      | 20G refreservation, so a full pool can still be cleaned up |
| `tank/media`         | `/mnt/storage/media`   | unencrypted                                |
| `tank/crypt`         | -                      | encryption root for the two below          |
| `tank/crypt/archive` | `/mnt/storage/archive` | irreplaceable data, `copies=2`             |
| `tank/crypt/backup`  | `/mnt/storage/backup`  | backups                                    |

`/` is a 4 GB tmpfs; what survives a reboot is listed in
`hosts/darkhero/impermanence.nix`.

## How encrypted data unlocks at boot

1. The initrd opens the LUKS keystore. systemd-cryptsetup tries the enrolled
   tokens in order: TPM2 (bound to PCR 7), then the YubiKey (FIDO2 PIN and
   touch), then prompts for the recovery key.
2. `zfs-load-keys` (initrd) copies `rpool-home.key` and `tank.key` to
   `/run/zfs-keys` (RAM) and loads the key of `rpool/safe/home`.
3. In stage 2, importing `tank` loads `tank/crypt` from
   `file:///run/zfs-keys/tank.key`.

Secrets to keep outside this machine, in Bitwarden: `rpool-home.key` and
`tank.key` (64 hex characters each), and the keystore recovery key - also on
paper. With a single YubiKey, the recovery key is the last way in if the TPM
stops unlocking and the YubiKey is unavailable at the same time.

Secure Boot is off, so the TPM releases the key to anything that boots on this
machine with the same PCR 7. See [Security](security.md#secure-boot).

## Keystore

```shell
KS=/dev/disk/by-partlabel/darkhero-keystore
sudo systemd-cryptenroll $KS                    # list enrolled slots
```

Enrolling needs an existing secret: the recovery key, or
`--unlock-fido2-device=auto` to authorise with the YubiKey.

```shell
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 $KS
sudo systemd-cryptenroll --fido2-device=auto $KS     # one YubiKey plugged in; PIN + touch
sudo systemd-cryptenroll --recovery-key $KS          # prints a new recovery key
```

Test a token without opening the device. Plain `cryptsetup` on NixOS does not
find systemd's token plugins, hence the library path:

```shell
SD=$(dirname $(dirname $(readlink -f /run/current-system/sw/bin/systemctl)))
tok() { sudo env LD_LIBRARY_PATH=$SD/lib/cryptsetup cryptsetup open --test-passphrase --token-only --token-type "$1" $KS && echo "$1 OK"; }
tok systemd-tpm2
tok systemd-fido2
sudo cryptsetup open --test-passphrase $KS && echo "recovery OK"   # type the recovery key
```

**Firmware or Secure Boot changes alter PCR 7.** The boot then falls back to
the YubiKey instead of unlocking silently. Re-enroll the TPM:

```shell
sudo systemd-cryptenroll --unlock-fido2-device=auto \
  --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 $KS
```

## Recovery

- **Boot fails after a rebuild:** pick the previous generation in systemd-boot.
- **`/home` does not mount:** the emergency shell asks for the root password
  (same as the user's). Run `zfs load-key rpool/safe/home`, paste the hex key
  from Bitwarden, then `systemctl default`.
- **The initrd fails** (rpool import, keystore): in systemd-boot press `e` on
  the entry and append `rd.systemd.debug_shell` for a root shell on tty9. A
  pool that refuses to import because it was not exported cleanly can be
  imported there with `zpool import -f -N rpool`.
- **`tank` does not import at boot:** the system still comes up;
  `sudo zpool import tank`, then `sudo zfs load-key tank/crypt` (the key file
  is in `/run/zfs-keys` if the keystore opened) and `sudo zfs mount -a`.

## Maintenance

- Scrub and TRIM run from timers (`services.zfs.autoScrub`, `services.zfs.trim`).
  `zpool status` shows the last scrub.
- ARC is capped at 16 GiB (`zfs.zfs_arc_max` in `disks.nix`).
- The kernel is the LTS series because ZFS is an out-of-tree module; see the
  comment on `boot.kernelPackages` in `hosts/darkhero/default.nix` before
  changing it.
- `tank` has no redundancy. A second disk of at least the same size becomes a
  mirror with one command, after partitioning it the same way (vdev names as
  `zpool status -P` shows them):
  `sudo zpool attach tank /dev/disk/by-partlabel/darkhero-tank /dev/disk/by-partlabel/<new-label>`.
- Before `zpool export` or `umount`, `fuser -vm <mountpoint>` shows what still
  holds it open.
