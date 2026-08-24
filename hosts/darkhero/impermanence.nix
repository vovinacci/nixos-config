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
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
