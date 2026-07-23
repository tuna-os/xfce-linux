kind: autotools
description: libxfce4ui - Common UI library for Xfce.

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/gtk3.bst
- xfce-linux/libxfce4util.bst
- xfce-linux/xfconf.bst

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
  url: https://gitlab.xfce.org/xfce/libxfce4ui.git
  track: libxfce4ui-[0-9]*
  ref: libxfce4ui-4.21.9-0-g9e5b8a1efbd887821d451bb68d582bdeee2c5e7b
