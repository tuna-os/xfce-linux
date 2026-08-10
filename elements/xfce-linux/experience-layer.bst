# XFCE Linux opinionated experience layer
#
# Provides an opinionated experience layer on top of vanilla XFCE (Aurora-equivalent):
# - Default wallpaper and adw-gtk3 branding defaults
# - Default dconf / xfconf opinionated desktop settings
# - System service integration hooks (uupd, hardware enablement, sudo-rs)
# - Base stack hooks for opinionated default applications

kind: stack
description: |
  XFCE Linux opinionated experience layer (Aurora equivalent).
  Integrates branding, defaults, system services, and experience stack.

depends:
  - xfce-linux/dconf-config.bst
  - xfce-linux/plymouth-theme.bst
  - xfce-linux/session-config.bst
