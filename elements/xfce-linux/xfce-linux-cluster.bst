# XFCE Linux cluster — dependencies and pre-built binaries
#
# Provides all dependencies for XFCE desktop environment with 55 binaries
# and 31 panel plugins from the hanthor/xfce-wayland monorepo.

kind: stack
description: |
  Complete XFCE desktop environment dependencies: 55 binaries + 31 panel plugins.
  Includes xfwl4 compositor, xfce4-panel, xfdesktop, thunar, xfce4-terminal,
  and all supporting applications and libraries.

depends:
  # The pre-built XFCE binaries themselves (now includes udev-enabled xfwl4)
  - xfce-linux/xfce-binaries.bst
  # XFCE default settings
  - xfce-linux/dconf-config.bst
  # XFCE users and config
  - xfce-linux/etc-config.bst




  # Core dependencies that everything needs

  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
  - freedesktop-sdk.bst:components/gtk3.bst
  - gnome-build-meta.bst:sdk/gtk.bst
  - freedesktop-sdk.bst:components/glib.bst
  
  # Wayland
  - freedesktop-sdk.bst:components/wayland.bst
  - freedesktop-sdk.bst:components/wayland-protocols.bst
  - freedesktop-sdk.bst:components/pixman.bst
  - freedesktop-sdk.bst:components/libdrm.bst

  # System
  - freedesktop-sdk.bst:components/systemd.bst
  - freedesktop-sdk.bst:components/dbus.bst
  - freedesktop-sdk.bst:components/pipewire.bst
  - freedesktop-sdk.bst:components/alsa-lib.bst

  # Libraries
  - freedesktop-sdk.bst:components/libnotify.bst
  - freedesktop-sdk.bst:components/polkit.bst
  - freedesktop-sdk.bst:components/libexif.bst
  - freedesktop-sdk.bst:components/libsoup.bst
  - freedesktop-sdk.bst:components/json-c.bst
  - freedesktop-sdk.bst:components/iso-codes.bst

  # gnome-build-meta deps
  - gnome-build-meta.bst:core-deps/vte.bst
  - gnome-build-meta.bst:core-deps/upower.bst
  - gnome-build-meta.bst:core-deps/libcanberra.bst
  - gnome-build-meta.bst:sdk/gtksourceview.bst

  # GStreamer
  - freedesktop-sdk.bst:components/gstreamer.bst
  - freedesktop-sdk.bst:components/gstreamer-plugins-base.bst
  - freedesktop-sdk.bst:components/gstreamer-plugins-good.bst

  # Python (for catfish, appfinder)
  - freedesktop-sdk.bst:components/python3.bst
