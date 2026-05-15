kind: autotools
description: dbus-glib - GLib bindings for D-Bus (required by xfce4-screensaver)

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
  - freedesktop-sdk.bst:components/glib.bst
  - freedesktop-sdk.bst:components/dbus.bst

build-depends:
  - freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
  - freedesktop-sdk.bst:components/gettext.bst
  - freedesktop-sdk.bst:components/gobject-introspection.bst

sources:
- kind: tar
  url: dbus_releases:dbus-glib/dbus-glib-0.114.tar.gz
  ref: c09c5c085b2a0e391b8ee7d783a1d63fe444e96717cc1814d61b5e8fc2827a7c

config:
  configure-commands:
    - ./configure --prefix=/usr --disable-gtk-doc --disable-static --enable-shared
