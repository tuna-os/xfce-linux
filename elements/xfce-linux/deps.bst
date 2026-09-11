# XFCE Linux dependencies stack
#
# Hand-picked OS services and utilities subset for the standalone XFCE Linux OCI layer.
# Omits meta-gnome-core-shell.bst, meta-gnome-core-apps.bst, and sdk-platform.bst.

kind: stack
description: |
  XFCE Linux desktop stack dependencies, OS services, and applications.

depends:
  # ── OS Core Services & Daemons ─────────────────────────
  - gnome-build-meta.bst:core-deps/NetworkManager.bst
  - gnome-build-meta.bst:core-deps/accountsservice.bst
  - gnome-build-meta.bst:core-deps/upower.bst
  - gnome-build-meta.bst:core-deps/fwupd.bst
  - gnome-build-meta.bst:core-deps/dconf.bst
  - gnome-build-meta.bst:core-deps/boltd.bst
  - gnome-build-meta.bst:core-deps/systemd-hwdb.bst
  - gnome-build-meta.bst:core/systemd-presets.bst
  - gnome-build-meta.bst:gnomeos-deps/preset-all.bst
  - gnome-build-meta.bst:gnomeos-deps/journald-config.bst
  - gnome-build-meta.bst:gnomeos-deps/ld-config.bst
  - gnome-build-meta.bst:gnomeos-deps/modprobe-config.bst
  - gnome-build-meta.bst:gnomeos-deps/debuginfod-config.bst
  - gnome-build-meta.bst:gnomeos-deps/nm-connectivity-config.bst
  - gnome-build-meta.bst:gnomeos-deps/wpa-supplicant-config.bst
  - gnome-build-meta.bst:gnomeos-deps/zram-generator.bst
  - gnome-build-meta.bst:gnomeos-deps/switcheroo-control.bst
  - gnome-build-meta.bst:gnomeos-deps/uresourced.bst
  - gnome-build-meta.bst:gnomeos-deps/iio-sensor-proxy.bst
  - gnome-build-meta.bst:gnomeos-deps/fprintd.bst
  - gnome-build-meta.bst:gnomeos-deps/firewalld.bst
  - gnome-build-meta.bst:gnomeos-deps/nftables.bst
  - gnome-build-meta.bst:gnomeos-deps/nss-mdns.bst
  - gnome-build-meta.bst:gnomeos-deps/NetworkManager-openconnect.bst
  - gnome-build-meta.bst:gnomeos-deps/NetworkManager-openvpn.bst
  - gnome-build-meta.bst:gnomeos-deps/NetworkManager-vpnc.bst
  - gnome-build-meta.bst:gnomeos-deps/noise-suppression-for-voice.bst
  - gnome-build-meta.bst:gnomeos-deps/nano-default-editor.bst
  - gnome-build-meta.bst:gnomeos-deps/android-udev-rules.bst
  - gnome-build-meta.bst:gnomeos-deps/bindfs.bst
  - gnome-build-meta.bst:gnomeos-deps/fish.bst
  - gnome-build-meta.bst:gnomeos-deps/opensc.bst
  - gnome-build-meta.bst:gnomeos-deps/pam-pkcs11.bst
  - gnome-build-meta.bst:gnomeos-deps/disable-iscsi.bst
  - gnome-build-meta.bst:gnomeos-deps/flathub-config.bst
  - gnome-build-meta.bst:gnomeos-deps/spice-vdagent.bst
  - gnome-build-meta.bst:gnomeos-deps/sysupdate-config.bst
  - gnome-build-meta.bst:gnomeos-deps/pcrlock-config.bst
  - gnome-build-meta.bst:gnomeos-deps/udev-hide-usr.bst
  - gnome-build-meta.bst:gnomeos-deps/hidraw-udev.bst
  - gnome-build-meta.bst:gnomeos-deps/vte-config.bst
  - gnome-build-meta.bst:gnomeos-deps/uinput.bst
  - gnome-build-meta.bst:gnomeos-deps/nvme-cli.bst
  - gnome-build-meta.bst:gnomeos-deps/mokutil.bst
  - gnome-build-meta.bst:gnomeos-deps/wsdd.bst
  - gnome-build-meta.bst:gnomeos-deps/alsa-ucm-conf.bst
  - gnome-build-meta.bst:gnomeos-deps/words.bst
  - gnome-build-meta.bst:core/gst-thumbnailers.bst

  # ── Portals ────────────────────────────────────────────
  - freedesktop-sdk.bst:components/xdg-desktop-portal.bst
  - gnome-build-meta.bst:core-deps/xdg-desktop-portal-gtk.bst

  # ── Audio & Multimedia ─────────────────────────────────
  - freedesktop-sdk.bst:components/pipewire-daemon.bst
  - freedesktop-sdk.bst:components/wireplumber.bst

  # ── Base Graphics & Drivers ────────────────────────────
  - freedesktop-sdk.bst:vm/mesa-default.bst
  - freedesktop-sdk.bst:components/geoclue.bst
  - freedesktop-sdk.bst:components/sof-firmware.bst
  - freedesktop-sdk.bst:components/steam-devices.bst
  - freedesktop-sdk.bst:components/wireless-regdb-bin.bst

  # ── Fonts & Input Methods ──────────────────────────────
  - freedesktop-sdk.bst:components/dejavu-fonts.bst
  - freedesktop-sdk.bst:components/liberation-fonts.bst
  - freedesktop-sdk.bst:components/noto-emoji.bst
  - gnome-build-meta.bst:gnomeos-deps/noto-cjk.bst
  - gnome-build-meta.bst:gnomeos-deps/ibus-anthy.bst
  - gnome-build-meta.bst:gnomeos-deps/ibus-hangul.bst
  - gnome-build-meta.bst:gnomeos-deps/ibus-libpinyin.bst
  - gnome-build-meta.bst:gnomeos-deps/ibus-typing-booster.bst

  # ── Utilities & Tools ──────────────────────────────────
  - freedesktop-sdk.bst:components/bash-completion.bst
  - freedesktop-sdk.bst:components/bash-config.bst
  - freedesktop-sdk.bst:components/btrfs-progs.bst
  - freedesktop-sdk.bst:components/ccid.bst
  - freedesktop-sdk.bst:components/dosfstools.bst
  - freedesktop-sdk.bst:components/iproute2.bst
  - freedesktop-sdk.bst:components/iputils.bst
  - freedesktop-sdk.bst:components/usbutils.bst
  - freedesktop-sdk.bst:components/rsync.bst
  - freedesktop-sdk.bst:components/less.bst
  - freedesktop-sdk.bst:components/nano.bst
  - freedesktop-sdk.bst:components/vim.bst
  - freedesktop-sdk.bst:components/man-db.bst
  - freedesktop-sdk.bst:components/open-iscsi.bst
  - freedesktop-sdk.bst:components/openssh-systemd.bst
  - freedesktop-sdk.bst:components/jq.bst
  - freedesktop-sdk.bst:components/git.bst
  - freedesktop-sdk.bst:components/git-lfs.bst
  - freedesktop-sdk.bst:components/buildstream2.bst
  - freedesktop-sdk.bst:components/debuginfod.bst
  - freedesktop-sdk.bst:components/bpf.bst
  - freedesktop-sdk.bst:components/vmlinuxh.bst
  - gnome-build-meta.bst:gnomeos-deps/just.bst
  - gnome-build-meta.bst:gnomeos-deps/wl-clipboard.bst
  - freedesktop-sdk.bst:components/libseat.bst
  - freedesktop-sdk.bst:components/libdisplay-info.bst

  # ── Containers ─────────────────────────────────────────
  - freedesktop-sdk.bst:components/podman.bst
  - freedesktop-sdk.bst:components/skopeo.bst
  - freedesktop-sdk.bst:components/containers-common.bst
  - gnome-build-meta.bst:gnomeos-deps/distrobox.bst
  - gnome-build-meta.bst:gnomeos-deps/toolbox.bst

  # ── XFCE Desktop Stack ─────────────────────────────────
  - xfce-linux/xfce-linux-cluster.bst
  - xfce-linux/experience-layer.bst
  - xfce-linux/session-config.bst
  - xfce-linux/plymouth-theme.bst

  # ── greetd + regreet Wayland greeter ────────────────────
  - xfce-linux/greetd.bst
  - xfce-linux/regreet.bst

(?):
- arch == "aarch64":
    depends:
      (>):
      - gnome-build-meta.bst:gnomeos-deps/deps-aarch64.bst
