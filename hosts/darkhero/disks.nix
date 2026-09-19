{ config, lib, pkgs, ... }:
# Storage layout. Partitions are addressed by GPT partition label and ZFS
# datasets by name, so nothing here depends on filesystem UUIDs and the file
# does not change when the disks are re-created. docs/storage.md describes the
# layout and the operations around it; keep the two in sync.
#
#   nvme-WDS100T1X0E-00AFY0_211417440503 (1 TB, system)
#     darkhero-esp       2 GiB  vfat   /boot/efi
#     darkhero-keystore 64 MiB  LUKS2  ZFS keys; TPM2 / FIDO2 / recovery key
#     darkhero-swap     16 GiB  swap   random key every boot
#     darkhero-rpool    rest    ZFS    rpool
#   ata-WDC_WD101EFBX-68B0AN0_VCJW40YP (10 TB, data)
#     darkhero-tank     whole  ZFS    tank, one vdev
{
  boot.supportedFilesystems = [ "zfs" ];
  # The host id ZFS stamps into the pool; importing on a machine with a
  # different id needs -f. First 8 hex digits of /etc/machine-id, which is
  # persisted (impermanence.nix), so it survives reinstalls that copy it over.
  networking.hostId = "315b9e37";
  # Never force-import: a pool that looks in use elsewhere should stop the
  # boot, not be imported anyway.
  boot.zfs.forceImportRoot = false;
  # The pool import services load no keys for rpool: rpool/safe/home is
  # unlocked by zfs-load-keys below, from the keystore. tank/crypt carries
  # keylocation=file:///run/zfs-keys/tank.key, which that same unit provides.
  boot.zfs.requestEncryptionCredentials = [ "tank/crypt" ];
  boot.zfs.extraPools = [ "tank" ];

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # ARC defaults to half of RAM (~46 GB here). It does shrink under memory
  # pressure, but slowly enough to fight games and builds for memory.
  boot.kernelParams = [ "zfs.zfs_arc_max=${toString (16 * 1024 * 1024 * 1024)}" ];

  # --- keystore -------------------------------------------------------------
  # A small LUKS2 volume holding the ZFS wrapping keys as hex files:
  #   rpool-home.key  -> rpool/safe/home
  #   tank.key        -> tank/crypt
  # Unlock order comes from systemd-cryptsetup's determine_token_type(): TPM2
  # (bound to PCR 7) first, then the YubiKey (FIDO2), then the recovery key at
  # the password prompt. Each mechanism is dropped and the next tried on
  # failure.
  #
  # Both are named explicitly: token-timeout only waits for configured
  # devices. The keystore is opened about 2s into boot, and the YubiKey
  # enumerates on USB at about 5s, so automatic discovery would find no FIDO2
  # device and go straight to the password prompt. With fido2-device=auto the
  # FIDO2 attempt waits for the token. A normal boot waits for nothing: the
  # TPM succeeds first and the timeout never starts.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.systemd.fido2.enable = true;
  boot.initrd.luks.devices.keystore = {
    device = "/dev/disk/by-partlabel/darkhero-keystore";
    crypttabExtraOpts = [ "tpm2-device=auto" "fido2-device=auto" "token-timeout=30s" ];
  };

  # Runs from the initrd's PATH (coreutils, mount, zfs via the ZFS module's
  # extraBin), not store paths, which initrd-ng would not copy in.
  # Copy the keys to /run (tmpfs, carried over switch-root), load the home
  # key, and unmount the keystore. /home is mounted in stage 2, after this
  # has run. If it fails, /home does not mount and the boot drops to the
  # emergency shell (root login, see profiles/workstation.nix), where
  # `zfs load-key rpool/safe/home` prompts for the hex key
  # (keylocation=prompt on the dataset; the key is in Bitwarden).
  boot.initrd.systemd.services.zfs-load-keys = {
    description = "Load ZFS encryption keys from the LUKS keystore";
    wantedBy = [ "initrd.target" ];
    requires = [ "systemd-cryptsetup@keystore.service" "zfs-import-rpool.service" ];
    after    = [ "systemd-cryptsetup@keystore.service" "zfs-import-rpool.service" ];
    # initrd.target too: with DefaultDependencies off, being wanted by a
    # target does not order the unit before it, and switch-root would stop a
    # still-running key load.
    before   = [ "initrd.target" "initrd-switch-root.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      mkdir -p -m 0700 /run/keystore /run/zfs-keys
      mount -t ext4 -o ro,noexec,nosuid,nodev /dev/mapper/keystore /run/keystore
      cp /run/keystore/*.key /run/zfs-keys/
      chmod 0400 /run/zfs-keys/*.key
      umount /run/keystore
      rmdir /run/keystore
      zfs load-key -L file:///run/zfs-keys/rpool-home.key rpool/safe/home
    '';
  };
  # The keystore's filesystem. The dm mapping stays open for the uptime
  # (cryptsetup units survive switch-root); it only exposes keys root can
  # already read in /run/zfs-keys.
  boot.initrd.supportedFilesystems = [ "ext4" ];

  # --- filesystems ----------------------------------------------------------
  fileSystems."/" = {
    device  = "none";
    fsType  = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  };

  # mountpoint=legacy on all three, so NixOS (not zfs-mount) mounts them and
  # stage 1 can mount /nix and /persist.
  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
  };

  fileSystems."/persist" = {
    device = "rpool/safe/persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "rpool/safe/home";
    fsType = "zfs";
  };

  # ESP readable by root only. fmask/dmask=0022 would leave loader/random-seed
  # world-readable (bootctl warns "security hole").
  fileSystems."/boot/efi" = {
    device  = "/dev/disk/by-partlabel/darkhero-esp";
    fsType  = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Plain dm-crypt with a fresh random key each boot: pages of the encrypted
  # home can land in swap, so swap must not be readable after power-off.
  # The partition label must stay unique - this overwrites whatever it names.
  swapDevices = [{
    device = "/dev/disk/by-partlabel/darkhero-swap";
    randomEncryption.enable = true;
  }];
}
