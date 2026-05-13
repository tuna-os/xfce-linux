set -euo pipefail
dnf install -y rust cargo gcc meson ninja-build \
    pkgconf-pkg-config wayland-devel wayland-protocols \
    libdrm-devel libinput-devel libseat-devel systemd-devel \
    mesa-libgbm-devel pixman-devel libxkbcommon-devel \
    gtk3-devel gobject-introspection-devel \
    xorg-x11-server-Xwayland-devel libxcb-devel \
    libxfce4util-devel libxfce4ui-devel xfconf-devel
cd /src/xfwl4
cargo build --release --no-default-features -F udev -F egl -F xwayland
cp target/release/xfwl4 /output/
