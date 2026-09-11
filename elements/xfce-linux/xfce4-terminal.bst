kind: meson
description: |
  Terminal emulator for the XFCE desktop environment (tuna-os/xfce-linux#158).

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/gettext.bst
- xfce-linux/xfce4-dev-tools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/gtk3.bst
- freedesktop-sdk.bst:components/glib.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- gnome-build-meta.bst:core-deps/vte.bst
- xfce-linux/libxfce4util.bst
- xfce-linux/libxfce4ui.bst
- xfce-linux/xfconf.bst

sources:
- kind: git_repo
  url: xfce:apps/xfce4-terminal.git
  track: xfce4-terminal-*
  ref: xfce4-terminal-1.2.0-0-gbcc92696a1526b85875f03c21b265bd376bce00d
