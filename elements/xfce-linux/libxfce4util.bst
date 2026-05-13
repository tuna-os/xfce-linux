kind: autotools
description: libxfce4util - Basic utility library for Xfce.

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
  - freedesktop-sdk.bst:components/glib.bst

build-depends:
  - xfce-linux/xfce4-dev-tools.bst
  - freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
  - freedesktop-sdk.bst:components/gtk-doc.bst
  - gnome-build-meta.bst:core-deps/intltool.bst
  - freedesktop-sdk.bst:components/gettext.bst
  - freedesktop-sdk.bst:components/gobject-introspection.bst
  - freedesktop-sdk.bst:components/vala.bst
  - freedesktop-sdk.bst:components/python3.bst

sources:
- kind: git_repo
  url: https://gitlab.xfce.org/xfce/libxfce4util.git
  track: master
  ref: libxfce4util-4.20.1-17-gcd33da2e55357a0571553572cccc3c0cb5d21004

config:
  configure-commands:
    - |
      export NOCONFIGURE=1
      ./autogen.sh
      ./configure --prefix=/usr --disable-gtk-doc
