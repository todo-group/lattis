# Publishing to crates.io

The primary crates.io package is `lattis`.

`lattis-python` is a PyPI extension crate and should normally not be published
to crates.io. `lattis-ffi` is optional; publish it only if downstream Rust/C
consumers need the C ABI crate directly.

## One-time setup

Create a crates.io account, verify your email address, and create an API token:

```text
https://crates.io/me
```

Store the token locally:

```sh
cargo login
```

The token is secret. Revoke it on crates.io if it is ever exposed.

## Preflight checks

Run tests:

```sh
cargo test -p lattis
```

Check the package without uploading:

```sh
cargo publish -p lattis --dry-run
```

Inspect the packaged files:

```sh
cargo package -p lattis --list
```

If the package contains unnecessary files, add `include` or `exclude` entries to
`rust/lattis/Cargo.toml` before publishing.

## Publish lattis

Publish:

```sh
cargo publish -p lattis
```

After publishing, docs.rs should build the documentation automatically:

```text
https://docs.rs/lattis
```

## Publishing lattis-ffi, if needed

Publish `lattis-ffi` only after `lattis` is available on crates.io.

Before publishing, make sure the dependency has both a path for local workspace
development and a version for crates.io resolution:

```toml
lattis = { version = "x.y.z", path = "../lattis" }
```

Then run:

```sh
cargo test -p lattis-ffi
cargo publish -p lattis-ffi --dry-run
cargo package -p lattis-ffi --list
cargo publish -p lattis-ffi
```

## Versioning rules

crates.io releases are permanent:

* a published version cannot be overwritten
* uploaded package contents cannot be deleted
* fixes require a new version

For example, after publishing `<version>`, a fix should be released as the next
SemVer-compatible version.

## Release checklist

1. Update `version` under `[workspace.package]` in the root `Cargo.toml`.
2. Run `cargo test -p lattis`.
3. Run `cargo publish -p lattis --dry-run`.
4. Inspect `cargo package -p lattis --list`.
5. Commit the release changes.
6. Tag the release, for example `v<version>`.
7. Run `cargo publish -p lattis`.
8. Confirm the crate page and docs.rs page are live.
