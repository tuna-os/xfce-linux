kind: autotools
description: |
  XFCE window manager and window themes (tuna-os/xfce-linux#158).
  Provides xfwm4 window themes required by the xfwl4 compositor.

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/gettext.bst
- xfce-linux/intltool.bst
- xfce-linux/xfce4-dev-tools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/gtk3.bst
- freedesktop-sdk.bst:components/glib.bst
- freedesktop-sdk.bst:components/libepoxy.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xinerama.bst
- freedesktop-sdk.bst:components/xorg-lib-xrandr.bst
- freedesktop-sdk.bst:components/xorg-lib-xcomposite.bst
- freedesktop-sdk.bst:components/xorg-lib-xdamage.bst
- freedesktop-sdk.bst:components/xorg-lib-xfixes.bst
- freedesktop-sdk.bst:components/xorg-lib-xrender.bst
- xfce-linux/libxfce4util.bst
- xfce-linux/libxfce4ui.bst
- xfce-linux/xfconf.bst

sources:
- kind: git_repo
  url: xfce:xfce/xfwm4.git
  track: xfwm4-*
  ref: xfwm4-4.20.0-0-g7cadce33226be955fa2677b97a1969701d246b80

config:
  configure-commands:
  - ./autogen.sh
  - ./configure --prefix=/usr --disable-static
