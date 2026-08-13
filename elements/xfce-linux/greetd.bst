kind: manual
description: |
  greetd — minimal, flexible login manager daemon. Session-manager half of
  the greetd + regreet Wayland greeter stack (ADR 0001, tuna-os/xfce-linux#39).

  Built but NOT activated by this element: greetd.service is installed
  disabled, and GDM remains the active display manager (xfce-linux-stack.bst
  unchanged). Switching the live ISO / default session over to greetd is a
  separate follow-up, once this survives the LUKS e2e's login-path assertions
  per the issue's own phased plan.

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/rust.bst
- freedesktop-sdk.bst:components/linux-pam.bst
- freedesktop-sdk.bst:components/linux-pam-base.bst
- freedesktop-sdk.bst:components/systemd.bst

sources:
- kind: git_repo
  url: https://git.sr.ht/~kennylevinsen/greetd
  track: "0.9.0"
  ref: f3f32498851c6775a9d9ca0d46239b9a6de78204
  directory: greetd
- kind: cargo2
  cargo-lock: greetd/Cargo.lock
  ref:
  -
    name: async-trait
    version: 0.1.60
  -
    name: autocfg
    version: 1.1.0
  -
    name: bitflags
    version: 1.3.2
  -
    name: bytes
    version: 1.3.0
  -
    name: cfg-if
    version: 1.0.0
  -
    name: enquote
    version: 1.1.0
  -
    name: getopts
    version: 0.2.21
  -
    name: itoa
    version: 1.0.5
  -
    name: libc
    version: 0.2.139
  -
    name: log
    version: 0.4.17
  -
    name: memchr
    version: 2.5.0
  -
    name: memoffset
    version: 0.7.1
  -
    name: mio
    version: 0.8.5
  -
    name: nix
    version: 0.26.1
  -
    name: pam-sys
    version: 0.5.6
  -
    name: pin-project-lite
    version: 0.2.9
  -
    name: pin-utils
    version: 0.1.0
  -
    name: proc-macro2
    version: 1.0.49
  -
    name: quote
    version: 1.0.23
  -
    name: rpassword
    version: 5.0.1
  -
    name: ryu
    version: 1.0.12
  -
    name: serde
    version: 1.0.152
  -
    name: serde_derive
    version: 1.0.152
  -
    name: serde_json
    version: 1.0.91
  -
    name: signal-hook-registry
    version: 1.4.0
  -
    name: socket2
    version: 0.4.7
  -
    name: static_assertions
    version: 1.1.0
  -
    name: syn
    version: 1.0.107
  -
    name: thiserror
    version: 1.0.38
  -
    name: thiserror-impl
    version: 1.0.38
  -
    name: tokio
    version: 1.24.0
  -
    name: tokio-macros
    version: 1.8.2
  -
    name: unicode-ident
    version: 1.0.6
  -
    name: unicode-width
    version: 0.1.10
  -
    name: users
    version: 0.11.0
  -
    name: wasi
    version: 0.11.0+wasi-snapshot-preview1
  -
    name: winapi
    version: 0.3.9
  -
    name: winapi-i686-pc-windows-gnu
    version: 0.4.0
  -
    name: winapi-x86_64-pc-windows-gnu
    version: 0.4.0
  -
    name: windows-sys
    version: 0.42.0
  -
    name: windows_aarch64_gnullvm
    version: 0.42.0
  -
    name: windows_aarch64_msvc
    version: 0.42.0
  -
    name: windows_i686_gnu
    version: 0.42.0
  -
    name: windows_i686_msvc
    version: 0.42.0
  -
    name: windows_x86_64_gnu
    version: 0.42.0
  -
    name: windows_x86_64_gnullvm
    version: 0.42.0
  -
    name: windows_x86_64_msvc
    version: 0.42.0

config:
  build-commands:
  - |
    cd greetd
    export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
    export RUSTFLAGS="-C relocation-model=pic"
    # Cargo dependencies are vendored via the cargo2 source (above) which
    # resolves + downloads all crates from Cargo.lock at fetch time.
    # --offline --frozen can then be used during the sandboxed build.
    cargo build --release --offline --frozen --workspace --exclude fakegreet

  install-commands:
  - |
    mkdir -p "%{install-root}/usr/bin" \
             "%{install-root}/usr/lib/systemd/system" \
             "%{install-root}/usr/lib/sysusers.d" \
             "%{install-root}%{sysconfdir}/greetd" \
             "%{install-root}%{sysconfdir}/pam.d"

    cat > "%{install-root}/usr/lib/sysusers.d/greetd.conf" <<'EOF'
    u greeter - "greetd greeter" /var/lib/greetd -
    m greeter video
    EOF
    install -m 0755 greetd/target/release/greetd "%{install-root}/usr/bin/greetd"
    install -m 0755 greetd/target/release/agreety "%{install-root}/usr/bin/agreety"
    install -m 0644 greetd/greetd.service "%{install-root}/usr/lib/systemd/system/greetd.service"

    # NOT FUNCTIONAL YET: this launches regreet under `cage`, which this
    # repo doesn't package (cage needs wlroots, unavailable in
    # freedesktop-sdk or gnome-build-meta — see deps.bst's comment). Kept
    # as the intended config rather than something bogus, since greetd.service
    # ships disabled and nothing exercises this file yet — but don't expect
    # it to actually start a session until a compositor is sorted out.
    cat > "%{install-root}%{sysconfdir}/greetd/config.toml" <<'EOF'
    [terminal]
    vt = 1

    [default_session]
    command = "cage -s -- /usr/bin/regreet"
    user = "greeter"

    [initial_session]
    command = "cage -s -- /usr/bin/regreet"
    user = "greeter"
    EOF

    # PAM stack: mirrors sddm.bst's rewrite target in this org's images —
    # freedesktop-sdk/gnomeos ships `system-auth` as the shared include,
    # not upstream sddm's own `system-local-login`/`system-login` names
    # (confirmed for tromso; UNCONFIRMED specifically for xfce-linux, which
    # has no other pam.d/* element to cross-check against yet).
    cat > "%{install-root}%{sysconfdir}/pam.d/greetd" <<'EOF'
    auth     include system-auth
    account  include system-auth
    password include system-auth
    session  include system-auth
    EOF
