kind: stack
description: XFCE Linux stack — freedesktop-sdk base plus XFCE desktop

depends:
  # XFCE Linux dependencies and applications
  - xfce-linux/deps.bst
  # gnome-build-meta gnomeos stack (provides freedesktop-sdk base)
  - gnome-build-meta.bst:oci/gnomeos/stack.bst

public:
  bst:
    integration-commands:
      # Wipe /var (may contain build-time state) and recreate with correct structure
      - rm -rfv /home /root /opt /mnt /srv /var
      - mkdir -p /var/home /var/roothome /var/opt /var/mnt /var/srv /var/tmp
      - ln -s var/home /home
      - ln -s var/roothome /root
      - ln -s var/opt /opt
      - ln -s var/mnt /mnt
      - ln -s var/srv /srv
      # HACK: Fix hardcoded paths in pre-built binaries
      - mkdir -p /var/home/james/dev/xfce-wayland
      - ln -s /usr /var/home/james/dev/xfce-wayland/install
      - ldconfig || true
      # Fix missing libraries
      - mkdir -p /usr/lib/x86_64-linux-gnu
      - ln -s /usr/lib64/libxfce4kbd-private-3.so.0 /usr/lib/x86_64-linux-gnu/libxfce4kbd-private-3.so.0
      - ln -s /usr/lib64/libxfconf-0.so.3 /usr/lib/x86_64-linux-gnu/libxfconf-0.so.3
      # Disable GNOME services that interfere with XFCE
      - systemctl disable gnome-initial-setup || true
      - systemctl enable gdm || true
      # Skip GNOME Initial Setup for new users
      - mkdir -p /etc/skel/.config
      - touch /etc/skel/.config/gnome-initial-setup-done
      # Force remove initial-setup autostart
      - rm -f /usr/share/applications/gnome-initial-setup.desktop
      - rm -f /etc/xdg/autostart/gnome-initial-setup.desktop
      - rm -f /usr/share/gnome-session/sessions/gnome-initial-setup.session
      # Configure GDM for XFCE
      - mkdir -p /etc/gdm
      - |
        cat > /etc/gdm/custom.conf <<EOF
        [daemon]
        AutomaticLoginEnable=True
        AutomaticLogin=xfce
        DefaultSession=xfce-wayland

        [debug]
        Enable=true
        EOF
      # Set default session for xfce user
      - mkdir -p /var/lib/AccountsService/users
      - |
        cat > /var/lib/AccountsService/users/xfce <<EOF
        [User]
        Session=xfce-wayland
        Icon=/usr/share/pixmaps/faces/user-generic.png
        SystemAccount=false
        EOF
      # Enable SSH
      - systemctl enable sshd || true
      - mkdir -p /root/.ssh
      - echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICPOZx220I8Av7KmEAOib4iAKZFCzPp8cwtzvteJJ7VB james@karnataka" > /root/.ssh/authorized_keys
      - chmod 700 /root/.ssh
      - chmod 600 /root/.ssh/authorized_keys
      - mkdir -p /etc/ssh/sshd_config.d
      - echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/01-permit-root-login.conf









