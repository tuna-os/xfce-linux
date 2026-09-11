kind: script
description: |
  XFCE Linux OCI image — Wayland desktop with xfwl4 compositor.

build-depends:
  - gnome-build-meta.bst:freedesktop-sdk.bst:components/fakecap.bst
  - gnome-build-meta.bst:freedesktop-sdk.bst:components/oci-builder.bst
  - freedesktop-sdk.bst:components/glib.bst
  - gnome-build-meta.bst:core-deps/dconf.bst
  - gnome-build-meta.bst:freedesktop-sdk.bst:vm/prepare-image.bst
  - oci/layers/xfce-linux-init-scripts.bst
  - filename: oci/layers/xfce-linux.bst
    config:
      location: /layer

environment:
  LD_PRELOAD: /usr/libexec/fakecap/fakecap.so
  FAKECAP_DB: /fakecap

variables:
  sysroot-seed: a1b2c3d4-e5f6-7890-abcd-ef1234567890

config:
  commands:
    - mkdir /fakecap
    - |
      prepare-image.sh \
         --sysroot /layer \
         --initscripts /initial_scripts \
         --seed "%{sysroot-seed}" \
         --noroot --noboot >/dev/null

    - |
      systemd-sysusers --root /layer

    - |
      if [ -d /layer/usr/share/glib-2.0/schemas ]; then
        glib-compile-schemas /layer/usr/share/glib-2.0/schemas
      fi

    # bootc images must not have both /etc and /usr/etc.
    - |
      if [ -d /layer/usr/etc ]; then
        mkdir -p /layer/etc
        cp -a /layer/usr/etc/. /layer/etc/
        rm -rf /layer/usr/etc
      fi

    - |
      if [ -d /layer/etc/dconf/db ]; then
        dconf update /layer/etc/dconf/db
      fi

    - |
      cd "%{install-root}"
      build-oci <<EOF
      mode: oci
      gzip: disabled
      images:
      - os: linux
        architecture: "%{go-arch}"
        layer: /layer
        comment: "Import XFCE Linux layer"
        config:
          Labels:
            'com.github.containers.toolbox': 'true'
            'org.opencontainers.image.title': 'XFCE Linux'
            'org.opencontainers.image.description': 'A Wayland-native XFCE desktop image with xfwl4 compositor'
            'org.opencontainers.image.vendor': 'XFCE Linux Project'
            'org.opencontainers.image.licenses': 'GPL-3.0'
            'org.opencontainers.image.url': 'https://github.com/tuna-os/xfce-linux'
            'org.opencontainers.image.source': 'https://github.com/tuna-os/xfce-linux'
            'containers.bootc': '1'
        index-annotations:
          'org.opencontainers.image.ref.name': 'ghcr.io/tuna-os/xfce-linux:latest'
      EOF
