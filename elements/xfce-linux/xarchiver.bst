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
  ref: 0.5.4.27-2-g46258fc17b34258b732503726201096d0d60d7f9

config:
  configure-commands:
  - ./autogen.sh
  - ./configure --prefix=/usr --disable-gtk2 --disable-doc
