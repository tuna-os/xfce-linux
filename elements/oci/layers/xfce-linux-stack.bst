kind: stack
description: XFCE Linux stack — hand-picked OS stack plus XFCE desktop

depends:
  # XFCE Linux dependencies and applications
  - xfce-linux/deps.bst
  - oci/os-release.bst

  # Hardware firmware and kernel / initramfs
  - freedesktop-sdk.bst:components/linux-firmware.bst
  - gnome-build-meta.bst:gnomeos/initramfs/signed-modules.bst
  - gnome-build-meta.bst:oci/initramfs.bst

  # Bootc integration
  - gnome-build-meta.bst:gnomeos-deps/bootc.bst
  - gnome-build-meta.bst:oci/integration/bootc-config.bst
  - gnome-build-meta.bst:oci/integration/lvm2-enable-activation.bst

  # System users and sudo configuration
  - freedesktop-sdk.bst:vm/config/useradd-ostree.bst
  - freedesktop-sdk.bst:vm/config/sudo.bst

public:
  bst:
    integration-commands:
      # Required for bootc / ostree filesystem layout
      - mkdir -p /boot /sysroot/ostree
      - ln -s sysroot/ostree ostree
      - rm -rfv /home /root /opt /mnt /srv /var
      - mkdir -p /var/home /var/roothome /var/opt /var/mnt /var/srv /var/tmp
      - ln -s var/home /home
      - ln -s var/roothome /root
      - ln -s var/opt /opt
      - ln -s var/mnt /mnt
      - ln -s var/srv /srv
      - touch /etc/machine-id
      - ldconfig || true









