kind: meson
description: |
  Session manager for the XFCE desktop environment (tuna-os/xfce-linux#158).

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst
- freedesktop-sdk.bst:components/gettext.bst
- xfce-linux/xfce4-dev-tools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/gtk3.bst
- freedesktop-sdk.bst:components/glib.bst
- freedesktop-sdk.bst:components/polkit.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-sm.bst
- freedesktop-sdk.bst:components/xorg-lib-ice.bst
- xfce-linux/libxfce4util.bst
- xfce-linux/libxfce4ui.bst
- xfce-linux/xfconf.bst
- xfce-linux/libxfce4windowing.bst

sources:
- kind: git_repo
  url: xfce:xfce/xfce4-session.git
  track: xfce4-session-*
  ref: xfce4-session-4.21.1-0-g5681e8b24d192ff572a52f80e9381d6543dfd2e0
