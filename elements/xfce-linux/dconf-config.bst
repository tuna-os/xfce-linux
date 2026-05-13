kind: manual
description: Install XFCE dconf default settings.

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: local
  path: files/dconf

config:
  install-commands:
    - |
      mkdir -p "%{install-root}/etc/dconf/db/local.d"
      cp 00-xfce-defaults "%{install-root}/etc/dconf/db/local.d/"
      cp 01-xfce-keybindings "%{install-root}/etc/dconf/db/local.d/"
      cp 02-xfce-lockscreen "%{install-root}/etc/dconf/db/local.d/"

variables:
  strip-binaries: ""

