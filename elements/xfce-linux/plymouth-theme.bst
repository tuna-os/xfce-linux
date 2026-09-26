kind: manual
description: >-
  XFCE-branded Plymouth boot splash. The gnomeos parent layer already ships
  plymouth with the bgrt/spinner theme and a GNOME watermark
  (gnome-build-meta gnomeos-deps/plymouth-gnome-theme.bst); this element
  shadows the watermark with the official XFCE logo from libxfce4ui and
  re-asserts the theme defaults. Files in the xfce-linux OCI layer overwrite
  the parent layer's at image assembly, so no bst overlap is involved.

sources:
- kind: remote
  url: xfce_files:xfce/libxfce4ui/-/raw/8347316a5b01ce0d561aa4e236b4d73d564e2b0e/icons/scalable/xfce4-logo.svg
  ref: 0307d47afcb70d62ba6af6285a0023a96f692015a9ad4887c7e472d7b4166257

build-depends:
- gnome-build-meta.bst:freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- gnome-build-meta.bst:freedesktop-sdk.bst:components/librsvg.bst

# Depend on the GNOME theme so this element stages after it in the compose
# and our watermark/defaults win the overlap.
runtime-depends:
- gnome-build-meta.bst:gnomeos-deps/plymouth-gnome-theme.bst

variables:
  strip-binaries: ''

config:
  install-commands:
  - |
    # Render the official XFCE logo (CC-BY-SA, xfce.org) at splash size.
    rsvg-convert -w 256 -h 256 xfce4-logo.svg -o watermark.png
    install -Dm644 watermark.png "%{install-root}%{datadir}/plymouth/themes/spinner/watermark.png"
    install -Dm644 watermark.png "%{install-root}%{datadir}/pixmaps/xfce-boot-logo.png"
    install -d "%{install-root}%{datadir}/plymouth"
    cat > "%{install-root}%{datadir}/plymouth/plymouthd.defaults" << 'EOF'
    [Daemon]
    Theme=bgrt
    ShowDelay=0
    DeviceTimeout=8
    EOF
  - |
    # bootc-installed systems: boot with `splash` so plymouth shows the
    # graphical splash and LUKS passphrase prompt. Deliberately no `quiet` —
    # CI's serial-log assertions depend on boot messages.
    install -d "%{install-root}/usr/lib/bootc/kargs.d"
    printf 'kargs = ["splash"]\n' > "%{install-root}/usr/lib/bootc/kargs.d/50-splash.toml"

public:
  bst:
    overlap-whitelist:
    - '%{datadir}/plymouth/plymouthd.defaults'
    - '%{datadir}/plymouth/themes/spinner/watermark.png'
