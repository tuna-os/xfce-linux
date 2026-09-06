kind: manual
description: |
  greetd — minimal, flexible login manager daemon. Session-manager half of
  the greetd + regreet Wayland greeter stack (ADR 0001, tuna-os/xfce-linux#39).

  Built but NOT activated by this element: greetd.service is installed
  disabled, and GDM remains the active display manager (xfce-linux-stack.bst
  unchanged). Switching the live ISO / default session over to greetd is a
  separate follow-up, once this survives the LUKS e2e's login-path assertions
  per the issue's own phased plan.

# buildsystem-make brings the C toolchain (gcc/binutils) into the build
# sandbox. rustc drives linking through clang, and without binutils' `ld`
# every crate's build script dies with "clang: error: unable to execute
# command: posix_spawn failed: No such file or directory" — the reason this
# element failed on every Multi-Runner run since it landed (#135). Same
# dependency shape as every cargo element in tuna-os/tromso.
build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst
- freedesktop-sdk.bst:components/pkg-config.bst
- freedesktop-sdk.bst:components/rust.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/linux-pam.bst
- freedesktop-sdk.bst:components/linux-pam-base.bst
- freedesktop-sdk.bst:components/systemd.bst

sources:
- kind: git_repo
  url: https://git.sr.ht/~kennylevinsen/greetd
  track: "0.9.0"
  ref: 0.9.0-0-gf3f32498851c6775a9d9ca0d46239b9a6de78204
  directory: greetd
- kind: cargo2
  cargo-lock: greetd/Cargo.lock
  ref:
  - kind: registry
    name: async-trait
    version: 0.1.60
    sha: 677d1d8ab452a3936018a687b20e6f7cf5363d713b732b8884001317b0e48aa3
  - kind: registry
    name: autocfg
    version: 1.1.0
    sha: d468802bab17cbc0cc575e9b053f41e72aa36bfa6b7f55e3529ffa43161b97fa
  - kind: registry
    name: bitflags
    version: 1.3.2
    sha: bef38d45163c2f1dde094a7dfd33ccf595c92905c8f8f4fdc18d06fb1037718a
  - kind: registry
    name: bytes
    version: 1.3.0
    sha: dfb24e866b15a1af2a1b663f10c6b6b8f397a84aadb828f12e5b289ec23a3a3c
  - kind: registry
    name: cfg-if
    version: 1.0.0
    sha: baf1de4339761588bc0619e3cbc0120ee582ebb74b53b4efbf79117bd2da40fd
  - kind: registry
    name: enquote
    version: 1.1.0
    sha: 06c36cb11dbde389f4096111698d8b567c0720e3452fd5ac3e6b4e47e1939932
  - kind: registry
    name: getopts
    version: 0.2.21
    sha: 14dbbfd5c71d70241ecf9e6f13737f7b5ce823821063188d7e46c41d371eebd5
  - kind: registry
    name: itoa
    version: 1.0.5
    sha: fad582f4b9e86b6caa621cabeb0963332d92eea04729ab12892c2533951e6440
  - kind: registry
    name: libc
    version: 0.2.139
    sha: 201de327520df007757c1f0adce6e827fe8562fbc28bfd9c15571c66ca1f5f79
  - kind: registry
    name: log
    version: 0.4.17
    sha: abb12e687cfb44aa40f41fc3978ef76448f9b6038cad6aef4259d3c095a2382e
  - kind: registry
    name: memchr
    version: 2.5.0
    sha: 2dffe52ecf27772e601905b7522cb4ef790d2cc203488bbd0e2fe85fcb74566d
  - kind: registry
    name: memoffset
    version: 0.7.1
    sha: 5de893c32cde5f383baa4c04c5d6dbdd735cfd4a794b0debdb2bb1b421da5ff4
  - kind: registry
    name: mio
    version: 0.8.5
    sha: e5d732bc30207a6423068df043e3d02e0735b155ad7ce1a6f76fe2baa5b158de
  - kind: registry
    name: nix
    version: 0.26.1
    sha: 46a58d1d356c6597d08cde02c2f09d785b09e28711837b1ed667dc652c08a694
  - kind: registry
    name: pam-sys
    version: 0.5.6
    sha: cd4858311a097f01a0006ef7d0cd50bca81ec430c949d7bf95cbefd202282434
  - kind: registry
    name: pin-project-lite
    version: 0.2.9
    sha: e0a7ae3ac2f1173085d398531c705756c94a4c56843785df85a60c1a0afac116
  - kind: registry
    name: pin-utils
    version: 0.1.0
    sha: 8b870d8c151b6f2fb93e84a13146138f05d02ed11c7e7c54f8826aaaf7c9f184
  - kind: registry
    name: proc-macro2
    version: 1.0.49
    sha: 57a8eca9f9c4ffde41714334dee777596264c7825420f521abc92b5b5deb63a5
  - kind: registry
    name: quote
    version: 1.0.23
    sha: 8856d8364d252a14d474036ea1358d63c9e6965c8e5c1885c18f73d70bff9c7b
  - kind: registry
    name: rpassword
    version: 5.0.1
    sha: ffc936cf8a7ea60c58f030fd36a612a48f440610214dc54bc36431f9ea0c3efb
  - kind: registry
    name: ryu
    version: 1.0.12
    sha: 7b4b9743ed687d4b4bcedf9ff5eaa7398495ae14e61cba0a295704edbc7decde
  - kind: registry
    name: serde
    version: 1.0.152
    sha: bb7d1f0d3021d347a83e556fc4683dea2ea09d87bccdf88ff5c12545d89d5efb
  - kind: registry
    name: serde_derive
    version: 1.0.152
    sha: af487d118eecd09402d70a5d72551860e788df87b464af30e5ea6a38c75c541e
  - kind: registry
    name: serde_json
    version: 1.0.91
    sha: 877c235533714907a8c2464236f5c4b2a17262ef1bd71f38f35ea592c8da6883
  - kind: registry
    name: signal-hook-registry
    version: 1.4.0
    sha: e51e73328dc4ac0c7ccbda3a494dfa03df1de2f46018127f60c693f2648455b0
  - kind: registry
    name: socket2
    version: 0.4.7
    sha: 02e2d2db9033d13a1567121ddd7a095ee144db4e1ca1b1bda3419bc0da294ebd
  - kind: registry
    name: static_assertions
    version: 1.1.0
    sha: a2eb9349b6444b326872e140eb1cf5e7c522154d69e7a0ffb0fb81c06b37543f
  - kind: registry
    name: syn
    version: 1.0.107
    sha: 1f4064b5b16e03ae50984a5a8ed5d4f8803e6bc1fd170a3cda91a1be4b18e3f5
  - kind: registry
    name: thiserror
    version: 1.0.38
    sha: 6a9cd18aa97d5c45c6603caea1da6628790b37f7a34b6ca89522331c5180fed0
  - kind: registry
    name: thiserror-impl
    version: 1.0.38
    sha: 1fb327af4685e4d03fa8cbcf1716380da910eeb2bb8be417e7f9fd3fb164f36f
  - kind: registry
    name: tokio
    version: 1.24.0
    sha: 7125661431c26622a80ca5051a2f936c9a678318e0351007b0cc313143024e5c
  - kind: registry
    name: tokio-macros
    version: 1.8.2
    sha: d266c00fde287f55d3f1c3e96c500c362a2b8c695076ec180f27918820bc6df8
  - kind: registry
    name: unicode-ident
    version: 1.0.6
    sha: 84a22b9f218b40614adcb3f4ff08b703773ad44fa9423e4e0d346d5db86e4ebc
  - kind: registry
    name: unicode-width
    version: 0.1.10
    sha: c0edd1e5b14653f783770bce4a4dabb4a5108a5370a5f5d8cfe8710c361f6c8b
  - kind: registry
    name: users
    version: 0.11.0
    sha: 24cc0f6d6f267b73e5a2cadf007ba8f9bc39c6a6f9666f8cf25ea809a153b032
  - kind: registry
    name: wasi
    version: 0.11.0+wasi-snapshot-preview1
    sha: 9c8d87e72b64a3b4db28d11ce29237c246188f4f51057d65a7eab63b7987e423
  - kind: registry
    name: winapi
    version: 0.3.9
    sha: 5c839a674fcd7a98952e593242ea400abe93992746761e38641405d28b00f419
  - kind: registry
    name: winapi-i686-pc-windows-gnu
    version: 0.4.0
    sha: ac3b87c63620426dd9b991e5ce0329eff545bccbbb34f3be09ff6fb6ab51b7b6
  - kind: registry
    name: winapi-x86_64-pc-windows-gnu
    version: 0.4.0
    sha: 712e227841d057c1ee1cd2fb22fa7e5a5461ae8e48fa2ca79ec42cfc1931183f
  - kind: registry
    name: windows-sys
    version: 0.42.0
    sha: 5a3e1820f08b8513f676f7ab6c1f99ff312fb97b553d30ff4dd86f9f15728aa7
  - kind: registry
    name: windows_aarch64_gnullvm
    version: 0.42.0
    sha: 41d2aa71f6f0cbe00ae5167d90ef3cfe66527d6f613ca78ac8024c3ccab9a19e
  - kind: registry
    name: windows_aarch64_msvc
    version: 0.42.0
    sha: dd0f252f5a35cac83d6311b2e795981f5ee6e67eb1f9a7f64eb4500fbc4dcdb4
  - kind: registry
    name: windows_i686_gnu
    version: 0.42.0
    sha: fbeae19f6716841636c28d695375df17562ca208b2b7d0dc47635a50ae6c5de7
  - kind: registry
    name: windows_i686_msvc
    version: 0.42.0
    sha: 84c12f65daa39dd2babe6e442988fc329d6243fdce47d7d2d155b8d874862246
  - kind: registry
    name: windows_x86_64_gnu
    version: 0.42.0
    sha: bf7b1b21b5362cbc318f686150e5bcea75ecedc74dd157d874d754a2ca44b0ed
  - kind: registry
    name: windows_x86_64_gnullvm
    version: 0.42.0
    sha: 09d525d2ba30eeb3297665bd434a54297e4170c7f1a44cad4ef58095b4cd2028
  - kind: registry
    name: windows_x86_64_msvc
    version: 0.42.0
    sha: f40009d85759725a34da6d89a94e63d7bdc50a862acf0dbc7c8e488f1edcb6f5
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
