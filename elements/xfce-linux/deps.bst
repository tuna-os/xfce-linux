# XFCE Linux dependencies stack
#
# Pulls in freedesktop-sdk base plus all dependencies needed for the
# XFCE desktop stack, xfwl4 compositor, and supporting applications.

kind: stack
description: |
  XFCE Linux desktop stack dependencies and applications.

depends:
  # gnome-build-meta base (provides freedesktop-sdk infrastructure)
  - gnome-build-meta.bst:gnomeos-deps/deps.bst

  # ── XFCE Desktop Stack (from our monorepo) ─────────────
  - xfce-linux/xfce-linux-cluster.bst

  # ── XFCE Opinionated Experience Layer (Aurora equivalent, xfce-linux#40) ─
  - xfce-linux/experience-layer.bst

  # ── XFCE Session Configuration & Branding ──────────────
  - xfce-linux/session-config.bst
  # XFCE-logo Plymouth splash (shadows the parent layer's GNOME watermark)
  - xfce-linux/plymouth-theme.bst

  # ── greetd + regreet Wayland greeter (ADR 0001, xfce-linux#39) ─────────
  # Built and installed, but NOT activated: GDM remains the default display
  # manager (xfce-linux-stack.bst is unchanged). greetd.service ships
  # disabled. Switching the live ISO / default session over is a separate
  # follow-up PR, once this survives the LUKS e2e's login-path assertions —
  # see the issue for the full phased plan.
  #
  # cage.bst (the Wayland kiosk compositor meant to host regreet, per the
  # ADR) was cut from this PR: a real `bst show` confirmed
  # freedesktop-sdk.bst:components/wlroots.bst doesn't exist — checked
  # every one of freedesktop-sdk's 737 components and gnome-build-meta's
  # element tree directly against the GitLab/GNOME-GitLab APIs, not
  # guessed. Packaging wlroots from source is out of scope here; greetd's
  # config still references `cage -s -- /usr/bin/regreet` as its session
  # command, so it needs a real compositor before it can run — tracked as
  # an open item, not silently papered over.
  - xfce-linux/greetd.bst
  - xfce-linux/regreet.bst

  # ── freedesktop-sdk utilities ──────────────────────────
  - freedesktop-sdk.bst:components/buildstream2.bst
  - freedesktop-sdk.bst:components/debuginfod.bst
  - freedesktop-sdk.bst:components/git.bst
  - freedesktop-sdk.bst:components/git-lfs.bst
  - freedesktop-sdk.bst:components/podman.bst
  - freedesktop-sdk.bst:components/skopeo.bst
  - freedesktop-sdk.bst:components/containers-common.bst

  # ── System tools ───────────────────────────────────────
  - freedesktop-sdk.bst:components/bpf.bst
  - freedesktop-sdk.bst:components/vmlinuxh.bst
  - gnome-build-meta.bst:gnomeos-deps/just.bst
  - gnome-build-meta.bst:gnomeos-deps/wl-clipboard.bst
  - freedesktop-sdk.bst:components/libseat.bst
  - freedesktop-sdk.bst:components/libdisplay-info.bst
