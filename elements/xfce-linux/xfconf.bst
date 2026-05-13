kind: autotools
description: xfconf - Xfce configuration daemon and library.

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
  - freedesktop-sdk.bst:components/glib.bst
  - freedesktop-sdk.bst:components/dbus.bst
  - xfce-linux/libxfce4util.bst

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
  url: https://gitlab.xfce.org/xfce/xfconf.git
  track: master
  ref: xfconf-4.21.2-6-g6655bb3f37eaf1d67269f46f29bd42e55d59c0bf
