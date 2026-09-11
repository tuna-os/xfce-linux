kind: autotools
description: |
  Application library for the XFCE desktop environment (tuna-os/xfce-linux#158).

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/gettext.bst
- freedesktop-sdk.bst:components/perl-uri.bst
- xfce-linux/intltool.bst
- xfce-linux/xfce4-dev-tools.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/gtk3.bst
- freedesktop-sdk.bst:components/glib.bst
- xfce-linux/libxfce4util.bst
- xfce-linux/libxfce4ui.bst

sources:
- kind: git_repo
  url: xfce:xfce/exo.git
  track: exo-*
  ref: exo-4.21.0-0-g4a0f43606076efa3e9b50b1f59cf11aa2c9b41ac

config:
  configure-commands:
  - ./autogen.sh
  - ./configure --prefix=/usr --disable-gtk-doc
