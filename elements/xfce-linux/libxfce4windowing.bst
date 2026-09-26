kind: meson
description: |
  Windowing environment abstraction library for XFCE (tuna-os/xfce-linux#158).

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/gobject-introspection.bst
- freedesktop-sdk.bst:components/vala.bst
- freedesktop-sdk.bst:components/gettext.bst
- freedesktop-sdk.bst:components/wayland-protocols.bst
- freedesktop-sdk.bst:components/wayland.bst
- xfce-linux/xfce4-dev-tools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/gtk3.bst
- freedesktop-sdk.bst:components/glib.bst
- freedesktop-sdk.bst:components/wayland.bst
- freedesktop-sdk.bst:components/libdisplay-info.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xrandr.bst
- xfce-linux/libxfce4util.bst

sources:
- kind: git_repo
  url: xfce:xfce/libxfce4windowing.git
  track: libxfce4windowing-*
  ref: libxfce4windowing-4.20.7-0-ge288652b65a103c64161307281116b838c5df643
