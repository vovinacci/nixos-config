# Security

## Overview

Secrets are managed with [SOPS](https://github.com/getsops/sops) using
[age](https://age-encryption.org/) encryption. Three keys can decrypt all secrets:

| Key          | Alias in .sops.yaml     | Location                            | Used when                                              |
|--------------|-------------------------|-------------------------------------|--------------------------------------------------------|
| Host age key | `host_darkhero_persist` | `/persist/var/lib/sops-nix/key.txt` | Boot-time secret decryption (automatic, no interaction) |
| User age key | `user_darkhero`         | `~/.config/sops/age/keys.txt`       | User-level decryption (outside this repo)              |
| YubiKey      | `yubikey_vovin`         | PIV slot 1 on the YubiKey           | Interactive editing (`sops` CLI)                       |

All three keys are stored as age public keys in `.sops.yaml`. Any of the three
corresponding private keys can decrypt any file matching `secrets/*.sops.yaml`.

**System secrets** (decrypted by sops-nix at boot) land in `/run/secrets/<name>`.
User secrets - git identity, local zsh config, SSH keys - are not in this
repository: they live, SOPS-encrypted to the same three recipients, in the user's
dotfiles repository, which restores them itself. Every key rotation below has to
be repeated there: the same `.sops.yaml` change, then
`sops updatekeys secrets/*.sops.yaml` in that repository.

### Current Secret Files

| File                        | Contents                                         |
|-----------------------------|--------------------------------------------------|
| `secrets/secrets.sops.yaml` | `user_password_hash` - login and root password   |

---

## Day-to-Day: Editing Secrets

Open a secret file for editing (requires YubiKey touch; PIN is cached per session):

```shell
sops secrets/secrets.sops.yaml
```

SOPS decrypts to a temp file, opens `$EDITOR`, then re-encrypts on save.

### Adding a New Secret Key to an Existing File

Open the file with `sops`, add the new key-value pair, save and exit. SOPS re-encrypts
the entire file for all configured recipients automatically.

### Viewing Without Editing

```shell
sops decrypt secrets/secrets.sops.yaml
```

---

## Day-to-Day: Adding a New Secret File

**Naming convention**: `secrets/<name>.sops.yaml`. The `.gitignore` blocks all `*.yaml`
under `secrets/` and explicitly allows `*.sops.yaml`, so only encrypted files are
tracked.

### Create and Encrypt

```shell
sops secrets/newfile.sops.yaml
```

SOPS reads `.sops.yaml`, finds the matching `creation_rules` pattern, and encrypts
using all configured age keys. The file is ready to commit once you save and exit.

### Reference in NixOS Config (System-Level)

```nix
# hosts/<name>/default.nix or profiles/workstation.nix
sops.secrets.my_secret = {};
# Available at runtime as /run/secrets/my_secret
```

For secrets needed during early boot (e.g. user passwords):

```nix
sops.secrets.my_secret = { neededForUsers = true; };
```

### Note: SSH Authorised Keys

Secrets decrypted at runtime land under `/run/secrets/`.
These paths do not exist during early boot when `openssh` reads `authorizedKeys`.
**Keep SSH public keys inline** in `profiles/workstation.nix` rather than referencing
a SOPS secret path.

---

## Key Rotation: YubiKey Replaced or Lost

The host key and user key remain valid, so re-encryption is possible without the old
YubiKey.

1. Generate a new PIV age identity on the new YubiKey:
   ```shell
   age-plugin-yubikey --generate --slot 1
   ```
   Note the new age public key printed at the end.

2. Update `.sops.yaml` - replace the old `yubikey_vovin` value with the new key.

3. Re-encrypt all secret files:
   ```shell
   sops updatekeys secrets/secrets.sops.yaml
   ```

4. Commit the updated `.sops.yaml` and `secrets/*.sops.yaml`.

---

## Key Rotation: Host Replaced

1. On the new machine, generate the host age key and print its public key. The
   config decrypts with this dedicated key (`sops.age.keyFile`), not with the
   SSH host key (`sops.age.sshKeyPaths = []`), so an `ssh-to-age` recipient
   would not work:
   ```shell
   sudo mkdir -p /persist/var/lib/sops-nix
   sudo nix shell nixpkgs#age -c age-keygen -o /persist/var/lib/sops-nix/key.txt
   sudo chmod 600 /persist/var/lib/sops-nix/key.txt
   sudo nix shell nixpkgs#age -c age-keygen -y /persist/var/lib/sops-nix/key.txt
   ```

2. Re-encrypt from a machine that can still decrypt (the YubiKey or user key)
   before the new host's first boot - it cannot decrypt the password hash
   until its key is a recipient.

3. Update `.sops.yaml` - replace `host_darkhero_persist` with the new public key.

4. Re-encrypt:
   ```shell
   sops updatekeys secrets/secrets.sops.yaml
   ```

5. Commit the updated files.

---

## Key Rotation: User Age Key

1. Generate a new age key:
   ```shell
   age-keygen -o /tmp/new_user_key.txt
   ```

2. Add the new public key to `~/.config/sops/age/keys.txt` alongside the old one.

3. Update `.sops.yaml` - replace `user_darkhero` with the new public key.

4. Re-encrypt:
   ```shell
   sops updatekeys secrets/secrets.sops.yaml
   ```

5. Remove the old private key from `~/.config/sops/age/keys.txt`.

6. Commit the updated files, then store the new private key securely.

---

## YubiKey: PIN Locked

If the YubiKey PIV PIN is blocked, reset the PIV application and regenerate the age
identity. The host key and user key allow re-encryption without the YubiKey.

1. Reset PIV:
   ```shell
   ykman piv reset
   ```

2. Regenerate the age identity in slot 1 (choose a touch policy):
   ```shell
   age-plugin-yubikey --generate --slot 1
   ```
   Note the new age public key.

3. Update `.sops.yaml` - replace `yubikey_vovin` with the new key.

4. Re-encrypt all secret files:
   ```shell
   sops updatekeys secrets/secrets.sops.yaml
   ```

5. Commit the updated `.sops.yaml` and `secrets/*.sops.yaml`.

---

## Secure Boot

Secure Boot is **disabled**. See [Storage](storage.md) for the unlock chain.

### Hardening Options

Two options, in increasing cost:

- **TPM2 with a PIN:** `systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto
  --tpm2-pcrs=7 --tpm2-with-pin=yes` on the keystore. A PIN at every boot; the
  TPM's dictionary-attack lockout keeps a short PIN safe. No configuration change.
- **Secure Boot with lanzaboote:** signed boot chain, keys in
  `/persist/var/lib/sbctl` (`/var/lib` is tmpfs), enrolled with
  `sbctl enroll-keys --microsoft` - the Microsoft keys are required for the GPU
  option ROM and Windows. The firmware is already in setup mode. lanzaboote
  does not install `boot.loader.systemd-boot.windows` entries, so Windows would
  move to the firmware boot menu. With Secure Boot on, lanzaboote's stub ignores
  kernel command-line edits, so recovery means turning Secure Boot off in the
  firmware, after which the YubiKey or recovery key unlocks. Enabling it changes
  PCR 7: re-enroll the TPM ([Storage](storage.md#keystore)).
