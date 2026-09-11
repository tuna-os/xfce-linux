kind: manual
description: XFCE Linux os-release configuration (pass-through element)

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: local
  path: files/etc/os-release

config:
  install-commands:
    - |
      mkdir -p "%{install-root}/usr/lib"
      sed \
        -e 's/^VERSION_ID=.*/VERSION_ID="%{image-version}"/' \
        -e 's/^IMAGE_VERSION=.*/IMAGE_VERSION="%{image-version}"/' \
        -e 's/^VERSION=.*/VERSION="%{image-version}"/' \
        os-release > "%{install-root}/usr/lib/os-release"

variables:
  strip-binaries: ""
  VERSION_ID: "%{image-version}"
  IMAGE_VERSION: "%{image-version}"




