kind: autotools
description: xfce4-dev-tools - Xfce development tools.

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
  - freedesktop-sdk.bst:components/glib.bst

build-depends:
  - freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
  - freedesktop-sdk.bst:components/libxslt.bst
  - freedesktop-sdk.bst:components/meson.bst
  - freedesktop-sdk.bst:components/cmake.bst
  - freedesktop-sdk.bst:components/asciidoc.bst
  - freedesktop-sdk.bst:components/docbook-xsl.bst
  - freedesktop-sdk.bst:components/docbook-xml.bst
  - gnome-build-meta.bst:core-deps/intltool.bst
  - freedesktop-sdk.bst:components/gtk-doc.bst
  - freedesktop-sdk.bst:components/gobject-introspection.bst
  - freedesktop-sdk.bst:components/python3.bst

sources:
- kind: git_repo
  url: https://gitlab.xfce.org/xfce/xfce4-dev-tools.git
  track: master
  ref: xfce4-dev-tools-4.21.0-10-g5b5dc8345eb6135480a2c9840e73884141649182

config:
  configure-commands:
    - |
      export NOCONFIGURE=1
      ./autogen.sh
      ./configure --prefix=/usr --disable-gtk-doc --disable-gtk-doc-html
      # HACK: Satisfy documentation requirements
      mkdir -p docs
      touch docs/xdt-csource.1
