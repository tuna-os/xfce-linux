kind: autotools
description: intltool — internationalization toolchain (required by xarchiver)

depends:
  - freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

build-depends:
  - freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst

sources:
- kind: tar
  url: https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz
  ref: 67c74d94196b153b774ab9f89b2fa6c6ba79352407037c8c14d5aeb334e959cd

config:
  configure-commands:
    - ./configure --prefix=/usr
