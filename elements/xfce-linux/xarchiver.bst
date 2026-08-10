kind: autotools
description: |
  xarchiver — GTK+ frontend for archiving tools (tar, zip, rar, 7z, etc.).
  The one real gap vs a standard vanilla-XFCE app checklist (tuna-os/xfce-linux#56).

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
  - freedesktop-sdk.bst:components/gtk3.bst
  - freedesktop-sdk.bst:components/glib.bst

build-depends:
  - freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
  - freedesktop-sdk.bst:components/gettext.bst
  - xfce-linux/intltool.bst

sources:
- kind: git_repo
  url: https://github.com/ib/xarchiver.git
  track: master
  ref: cfea5d13c7dc6188e4c89ace117dfeed08843d25

config:
  configure-commands:
    - ./autogen.sh
    - ./configure --prefix=/usr --disable-gtk2 --disable-doc
