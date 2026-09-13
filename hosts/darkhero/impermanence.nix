{ config, ... }: {
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
      "/var/lib/docker"
      "/var/lib/nixos"
      "/var/lib/bluetooth"
      # fwupd metadata cache; without it every boot re-downloads the LVFS index.
      "/var/lib/fwupd"
      # systemd timer stamps. Without these, Persistent= timers (nh-clean,
      # fwupd-refresh, fstrim) reset their "last run" on every boot and a
      # weekly timer on a machine rebooted more often than weekly never fires.
      "/var/lib/systemd/timers"
      # Kernel logs rescued from EFI pstore after a crash. systemd-pstore moves
      # them out of NVRAM on the next boot, so on tmpfs they were deleted from
      # the only place that held them and then lost at the following reboot.
      "/var/lib/systemd/pstore"
      "/var/lib/systemd/coredump"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
