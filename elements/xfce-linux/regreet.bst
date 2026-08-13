kind: manual
description: |
  regreet — GTK4 greeter for greetd, themed for XFCE Linux (ADR 0001,
  tuna-os/xfce-linux#39). Meant to run under cage until xfwl4 can host it
  directly, per the ADR — but this repo doesn't package cage yet (it
  needs wlroots, unavailable in freedesktop-sdk/gnome-build-meta; see
  deps.bst). This element builds and installs the binary regardless,
  since it's independently useful to have ready, but nothing launches it.

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:components/rust.bst
- gnome-build-meta.bst:sdk/gtk.bst
- freedesktop-sdk.bst:components/glib.bst
- freedesktop-sdk.bst:components/libxml2.bst

sources:
- kind: git_repo
  url: https://github.com/rharish101/ReGreet.git
  track: "0.5.0"
  ref: 290e6f8d65b7034c5b63bc950a20bcf8277ebe5f
  directory: regreet
- kind: cargo2
  cargo-lock: regreet/Cargo.lock
  ref:
  -
    name: adler2
    version: 2.0.1
  -
    name: aho-corasick
    version: 1.1.4
  -
    name: allocator-api2
    version: 0.2.21
  -
    name: android_system_properties
    version: 0.1.5
  -
    name: anstream
    version: 1.0.0
  -
    name: anstyle
    version: 1.0.14
  -
    name: anstyle-parse
    version: 1.0.0
  -
    name: anstyle-query
    version: 1.1.5
  -
    name: anstyle-wincon
    version: 3.0.11
  -
    name: anyhow
    version: 1.0.102
  -
    name: async-broadcast
    version: 0.7.2
  -
    name: async-channel
    version: 2.5.0
  -
    name: async-executor
    version: 1.14.0
  -
    name: async-fs
    version: 2.2.0
  -
    name: async-global-executor
    version: 3.1.0
  -
    name: async-io
    version: 2.6.0
  -
    name: async-lock
    version: 3.4.2
  -
    name: async-process
    version: 2.5.0
  -
    name: async-recursion
    version: 1.1.1
  -
    name: async-signal
    version: 0.2.14
  -
    name: async-task
    version: 4.7.1
  -
    name: async-trait
    version: 0.1.89
  -
    name: atomic-waker
    version: 1.1.2
  -
    name: autocfg
    version: 1.5.0
  -
    name: bitflags
    version: 2.11.1
  -
    name: blocking
    version: 1.6.2
  -
    name: bumpalo
    version: 3.20.2
  -
    name: bytemuck
    version: 1.25.0
  -
    name: bytes
    version: 1.11.1
  -
    name: cairo-rs
    version: 0.21.5
  -
    name: cairo-sys-rs
    version: 0.21.5
  -
    name: cc
    version: 1.2.61
  -
    name: cfg-expr
    version: 0.20.7
  -
    name: cfg-if
    version: 1.0.4
  -
    name: cfg_aliases
    version: 0.2.1
  -
    name: chrono
    version: 0.4.44
  -
    name: chrono-tz
    version: 0.9.0
  -
    name: chrono-tz
    version: 0.10.4
  -
    name: chrono-tz-build
    version: 0.3.0
  -
    name: clap
    version: 4.6.1
  -
    name: clap_builder
    version: 4.6.0
  -
    name: clap_derive
    version: 4.6.1
  -
    name: clap_lex
    version: 1.1.0
  -
    name: colorchoice
    version: 1.0.5
  -
    name: concurrent-queue
    version: 2.5.0
  -
    name: const_format
    version: 0.2.36
  -
    name: const_format_proc_macros
    version: 0.2.34
  -
    name: core-foundation-sys
    version: 0.8.7
  -
    name: crc32fast
    version: 1.5.0
  -
    name: crossbeam-channel
    version: 0.5.15
  -
    name: crossbeam-deque
    version: 0.8.6
  -
    name: crossbeam-epoch
    version: 0.9.18
  -
    name: crossbeam-utils
    version: 0.8.21
  -
    name: crunchy
    version: 0.2.4
  -
    name: deranged
    version: 0.5.8
  -
    name: dlib
    version: 0.5.3
  -
    name: dunce
    version: 1.0.5
  -
    name: educe
    version: 0.6.0
  -
    name: either
    version: 1.16.0
  -
    name: endi
    version: 1.1.1
  -
    name: enum-ordinalize
    version: 4.3.2
  -
    name: enum-ordinalize-derive
    version: 4.3.2
  -
    name: enumflags2
    version: 0.7.12
  -
    name: enumflags2_derive
    version: 0.7.12
  -
    name: env_filter
    version: 1.0.1
  -
    name: env_logger
    version: 0.11.10
  -
    name: equivalent
    version: 1.0.2
  -
    name: errno
    version: 0.3.14
  -
    name: event-listener
    version: 5.4.1
  -
    name: event-listener-strategy
    version: 0.5.4
  -
    name: fastrand
    version: 2.4.1
  -
    name: field-offset
    version: 0.3.6
  -
    name: file-rotate
    version: 0.8.0
  -
    name: find-msvc-tools
    version: 0.1.9
  -
    name: flate2
    version: 1.1.9
  -
    name: flume
    version: 0.11.1
  -
    name: foldhash
    version: 0.1.5
  -
    name: foldhash
    version: 0.2.0
  -
    name: foreign-types
    version: 0.5.0
  -
    name: foreign-types-macros
    version: 0.2.3
  -
    name: foreign-types-shared
    version: 0.3.1
  -
    name: fragile
    version: 2.1.0
  -
    name: freedesktop_entry_parser
    version: 2.0.1
  -
    name: futures
    version: 0.3.32
  -
    name: futures-channel
    version: 0.3.32
  -
    name: futures-core
    version: 0.3.32
  -
    name: futures-executor
    version: 0.3.32
  -
    name: futures-io
    version: 0.3.32
  -
    name: futures-lite
    version: 2.6.1
  -
    name: futures-macro
    version: 0.3.32
  -
    name: futures-sink
    version: 0.3.32
  -
    name: futures-task
    version: 0.3.32
  -
    name: futures-timer
    version: 3.0.4
  -
    name: futures-util
    version: 0.3.32
  -
    name: gdk-pixbuf
    version: 0.21.5
  -
    name: gdk-pixbuf-sys
    version: 0.21.5
  -
    name: gdk4
    version: 0.10.3
  -
    name: gdk4-sys
    version: 0.10.3
  -
    name: getrandom
    version: 0.2.17
  -
    name: getrandom
    version: 0.3.4
  -
    name: getrandom
    version: 0.4.2
  -
    name: gio
    version: 0.21.5
  -
    name: gio-sys
    version: 0.21.5
  -
    name: glib
    version: 0.21.5
  -
    name: glib-macros
    version: 0.21.5
  -
    name: glib-sys
    version: 0.21.5
  -
    name: glob
    version: 0.3.3
  -
    name: glycin
    version: 3.0.8
  -
    name: glycin-common
    version: 1.0.3
  -
    name: glycin-utils
    version: 4.0.4
  -
    name: gobject-sys
    version: 0.21.5
  -
    name: graphene-rs
    version: 0.21.5
  -
    name: graphene-sys
    version: 0.21.5
  -
    name: greetd_ipc
    version: 0.10.3
  -
    name: gsk4
    version: 0.10.3
  -
    name: gsk4-sys
    version: 0.10.3
  -
    name: gtk4
    version: 0.10.3
  -
    name: gtk4-macros
    version: 0.10.3
  -
    name: gtk4-sys
    version: 0.10.3
  -
    name: gufo-common
    version: 1.1.0
  -
    name: gufo-exif
    version: 0.3.1
  -
    name: half
    version: 2.7.1
  -
    name: hashbrown
    version: 0.15.5
  -
    name: hashbrown
    version: 0.17.0
  -
    name: heck
    version: 0.5.0
  -
    name: hermit-abi
    version: 0.5.2
  -
    name: hex
    version: 0.4.3
  -
    name: humantime
    version: 2.3.0
  -
    name: humantime-serde
    version: 1.1.1
  -
    name: iana-time-zone
    version: 0.1.65
  -
    name: iana-time-zone-haiku
    version: 0.1.2
  -
    name: id-arena
    version: 2.3.0
  -
    name: indexmap
    version: 2.11.4
  -
    name: is_terminal_polyfill
    version: 1.70.2
  -
    name: itoa
    version: 1.0.18
  -
    name: jiff
    version: 0.2.24
  -
    name: jiff-static
    version: 0.2.24
  -
    name: jobserver
    version: 0.1.34
  -
    name: js-sys
    version: 0.3.97
  -
    name: konst
    version: 0.2.20
  -
    name: konst_macro_rules
    version: 0.2.19
  -
    name: lazy_static
    version: 1.5.0
  -
    name: lcms2
    version: 6.1.1
  -
    name: lcms2-sys
    version: 4.0.6
  -
    name: leb128fmt
    version: 0.1.0
  -
    name: libc
    version: 0.2.186
  -
    name: libloading
    version: 0.8.9
  -
    name: libseccomp
    version: 0.4.0
  -
    name: libseccomp-sys
    version: 0.3.0
  -
    name: linux-raw-sys
    version: 0.12.1
  -
    name: localzone
    version: 0.3.1
  -
    name: lock_api
    version: 0.4.14
  -
    name: log
    version: 0.4.29
  -
    name: lru
    version: 0.18.0
  -
    name: memchr
    version: 2.8.0
  -
    name: memfd
    version: 0.6.5
  -
    name: memmap2
    version: 0.9.10
  -
    name: memoffset
    version: 0.9.1
  -
    name: miniz_oxide
    version: 0.8.9
  -
    name: mio
    version: 1.2.0
  -
    name: nanorand
    version: 0.7.0
  -
    name: nix
    version: 0.30.1
  -
    name: nom
    version: 8.0.0
  -
    name: nu-ansi-term
    version: 0.50.3
  -
    name: num-conv
    version: 0.1.0
  -
    name: num-traits
    version: 0.2.19
  -
    name: num_threads
    version: 0.1.7
  -
    name: once_cell
    version: 1.21.4
  -
    name: once_cell_polyfill
    version: 1.70.2
  -
    name: ordered-stream
    version: 0.2.0
  -
    name: pango
    version: 0.21.5
  -
    name: pango-sys
    version: 0.21.5
  -
    name: parking
    version: 2.2.1
  -
    name: parse-zoneinfo
    version: 0.3.1
  -
    name: paste
    version: 1.0.15
  -
    name: phf
    version: 0.11.3
  -
    name: phf
    version: 0.12.1
  -
    name: phf_codegen
    version: 0.11.3
  -
    name: phf_generator
    version: 0.11.3
  -
    name: phf_shared
    version: 0.11.3
  -
    name: phf_shared
    version: 0.12.1
  -
    name: pin-project-lite
    version: 0.2.17
  -
    name: piper
    version: 0.2.5
  -
    name: pkg-config
    version: 0.3.33
  -
    name: polling
    version: 3.11.0
  -
    name: portable-atomic
    version: 1.13.1
  -
    name: portable-atomic-util
    version: 0.2.7
  -
    name: powerfmt
    version: 0.2.0
  -
    name: prettyplease
    version: 0.2.37
  -
    name: proc-macro-crate
    version: 3.5.0
  -
    name: proc-macro2
    version: 1.0.106
  -
    name: pure-rust-locales
    version: 0.8.2
  -
    name: quote
    version: 1.0.45
  -
    name: r-efi
    version: 5.3.0
  -
    name: r-efi
    version: 6.0.0
  -
    name: rand
    version: 0.8.6
  -
    name: rand_core
    version: 0.6.4
  -
    name: rayon
    version: 1.12.0
  -
    name: rayon-core
    version: 1.13.0
  -
    name: regex
    version: 1.12.3
  -
    name: regex-automata
    version: 0.4.14
  -
    name: regex-syntax
    version: 0.8.10
  -
    name: relm4
    version: 0.10.0
  -
    name: relm4-css
    version: 0.10.0
  -
    name: relm4-macros
    version: 0.10.0
  -
    name: rmp
    version: 0.8.15
  -
    name: rmp-serde
    version: 1.3.1
  -
    name: rustc_version
    version: 0.4.1
  -
    name: rustix
    version: 1.1.4
  -
    name: rustversion
    version: 1.0.22
  -
    name: scopeguard
    version: 1.2.0
  -
    name: semver
    version: 1.0.28
  -
    name: serde
    version: 1.0.228
  -
    name: serde_core
    version: 1.0.228
  -
    name: serde_derive
    version: 1.0.228
  -
    name: serde_json
    version: 1.0.149
  -
    name: serde_repr
    version: 0.1.20
  -
    name: serde_spanned
    version: 0.6.9
  -
    name: serde_spanned
    version: 1.1.1
  -
    name: sharded-slab
    version: 0.1.7
  -
    name: shlex
    version: 1.3.0
  -
    name: signal-hook-registry
    version: 1.4.8
  -
    name: simd-adler32
    version: 0.3.9
  -
    name: siphasher
    version: 1.0.3
  -
    name: slab
    version: 0.4.12
  -
    name: smallvec
    version: 1.15.1
  -
    name: socket2
    version: 0.6.3
  -
    name: spin
    version: 0.9.8
  -
    name: static_assertions
    version: 1.1.0
  -
    name: strsim
    version: 0.11.1
  -
    name: symlink
    version: 0.1.0
  -
    name: syn
    version: 2.0.117
  -
    name: sys-locale
    version: 0.3.2
  -
    name: system-deps
    version: 7.0.8
  -
    name: target-lexicon
    version: 0.13.3
  -
    name: tempfile
    version: 3.27.0
  -
    name: thiserror
    version: 1.0.69
  -
    name: thiserror
    version: 2.0.18
  -
    name: thiserror-impl
    version: 1.0.69
  -
    name: thiserror-impl
    version: 2.0.18
  -
    name: thread_local
    version: 1.1.9
  -
    name: time
    version: 0.3.45
  -
    name: time-core
    version: 0.1.7
  -
    name: time-macros
    version: 0.2.25
  -
    name: tokio
    version: 1.52.1
  -
    name: tokio-stream
    version: 0.1.18
  -
    name: toml
    version: 0.8.23
  -
    name: toml
    version: 1.1.0+spec-1.1.0
  -
    name: toml_datetime
    version: 0.6.11
  -
    name: toml_datetime
    version: 1.1.1+spec-1.1.0
  -
    name: toml_edit
    version: 0.22.27
  -
    name: toml_edit
    version: 0.25.6+spec-1.1.0
  -
    name: toml_parser
    version: 1.1.2+spec-1.1.0
  -
    name: toml_write
    version: 0.1.2
  -
    name: toml_writer
    version: 1.1.1+spec-1.1.0
  -
    name: tracing
    version: 0.1.44
  -
    name: tracing-appender
    version: 0.2.5
  -
    name: tracing-attributes
    version: 0.1.31
  -
    name: tracing-core
    version: 0.1.36
  -
    name: tracing-log
    version: 0.2.0
  -
    name: tracing-subscriber
    version: 0.3.23
  -
    name: tracker
    version: 0.2.2
  -
    name: tracker-macros
    version: 0.2.2
  -
    name: uds_windows
    version: 1.2.1
  -
    name: unicode-ident
    version: 1.0.24
  -
    name: unicode-xid
    version: 0.2.6
  -
    name: utf8parse
    version: 0.2.2
  -
    name: uuid
    version: 1.23.1
  -
    name: valuable
    version: 0.1.1
  -
    name: version-compare
    version: 0.2.1
  -
    name: wasi
    version: 0.11.1+wasi-snapshot-preview1
  -
    name: wasip2
    version: 1.0.1+wasi-0.2.4
  -
    name: wasip3
    version: 0.4.0+wasi-0.3.0-rc-2026-01-06
  -
    name: wasm-bindgen
    version: 0.2.120
  -
    name: wasm-bindgen-macro
    version: 0.2.120
  -
    name: wasm-bindgen-macro-support
    version: 0.2.120
  -
    name: wasm-bindgen-shared
    version: 0.2.120
  -
    name: wasm-encoder
    version: 0.244.0
  -
    name: wasm-metadata
    version: 0.244.0
  -
    name: wasmparser
    version: 0.244.0
  -
    name: windows
    version: 0.54.0
  -
    name: windows-core
    version: 0.54.0
  -
    name: windows-core
    version: 0.62.2
  -
    name: windows-implement
    version: 0.60.2
  -
    name: windows-interface
    version: 0.59.3
  -
    name: windows-link
    version: 0.2.1
  -
    name: windows-result
    version: 0.1.2
  -
    name: windows-result
    version: 0.4.1
  -
    name: windows-strings
    version: 0.5.1
  -
    name: windows-sys
    version: 0.61.2
  -
    name: windows-targets
    version: 0.52.6
  -
    name: windows_aarch64_gnullvm
    version: 0.52.6
  -
    name: windows_aarch64_msvc
    version: 0.52.6
  -
    name: windows_i686_gnu
    version: 0.52.6
  -
    name: windows_i686_gnullvm
    version: 0.52.6
  -
    name: windows_i686_msvc
    version: 0.52.6
  -
    name: windows_x86_64_gnu
    version: 0.52.6
  -
    name: windows_x86_64_gnullvm
    version: 0.52.6
  -
    name: windows_x86_64_msvc
    version: 0.52.6
  -
    name: winnow
    version: 0.7.15
  -
    name: winnow
    version: 1.0.2
  -
    name: wit-bindgen
    version: 0.46.0
  -
    name: wit-bindgen
    version: 0.51.0
  -
    name: wit-bindgen-core
    version: 0.51.0
  -
    name: wit-bindgen-rust
    version: 0.51.0
  -
    name: wit-bindgen-rust-macro
    version: 0.51.0
  -
    name: wit-component
    version: 0.244.0
  -
    name: wit-parser
    version: 0.244.0
  -
    name: yeslogic-fontconfig-sys
    version: 6.0.1
  -
    name: zbus
    version: 5.13.2
  -
    name: zbus_macros
    version: 5.13.2
  -
    name: zbus_names
    version: 4.3.1
  -
    name: zerocopy
    version: 0.8.50
  -
    name: zerocopy-derive
    version: 0.8.50
  -
    name: zmij
    version: 1.0.21
  -
    name: zvariant
    version: 5.9.2
  -
    name: zvariant_derive
    version: 5.9.2
  -
    name: zvariant_utils
    version: 3.3.0

config:
  build-commands:
  - |
    cd regreet
    export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
    export RUSTFLAGS="-C relocation-model=pic"
    # Cargo dependencies are vendored via the cargo2 source (above) which
    # resolves + downloads all crates from Cargo.lock at fetch time.
    # --offline --frozen can then be used during the sandboxed build.
    cargo build --release --offline --frozen

  install-commands:
  - |
    mkdir -p "%{install-root}/usr/bin" \
             "%{install-root}%{sysconfdir}/greetd" \
             "%{install-root}/usr/lib/tmpfiles.d" \
             "%{install-root}/usr/share/backgrounds"
    install -m 0755 regreet/target/release/regreet "%{install-root}/usr/bin/regreet"
    install -m 0644 regreet/systemd-tmpfiles.conf "%{install-root}/usr/lib/tmpfiles.d/regreet.conf"

    # XFCE Linux branding: reuses the Plymouth splash background if present,
    # falls back to regreet's own sample config otherwise. Real theming
    # (colors/logo matching xfce-linux/plymouth-theme.bst) is left for a
    # follow-up once the greeter actually renders on real hardware/QEMU.
    sed 's#/usr/share/backgrounds/greeter.jpg#/usr/share/backgrounds/xfce-linux/default.png#' \
      regreet/regreet.sample.toml > "%{install-root}%{sysconfdir}/greetd/regreet.toml" \
      || install -m 0644 regreet/regreet.sample.toml "%{install-root}%{sysconfdir}/greetd/regreet.toml"
