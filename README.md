# bazzite-workstation

Custom Universal Blue image built on top of `ghcr.io/ublue-os/bazzite-gnome:testing`.

This image keeps Bazzite's GNOME desktop and low-level hardware stack, trims the most obvious gaming-oriented desktop packages, and adds workstation/developer host tooling without changing your shell or IDE choice:
- `nushell`
- `micro`
- `Incus`
- `Docker`
- `libvirt` / `virt-manager`
- `cockpit-machines`
- Podman helper tools

## What Changes

Base image:
- `ghcr.io/ublue-os/bazzite-gnome:testing`

Added host packages:
- `nushell`
- `micro`
- `incus`
- `incus-agent`
- `incus-client`
- `incus-selinux`
- `docker-ce`
- `docker-ce-cli`
- `docker-buildx-plugin`
- `docker-compose-plugin`
- `docker-ce-rootless-extras`
- `docker-model-plugin`
- `libvirt-daemon-kvm`
- `libvirt-dbus`
- `libvirt-glib`
- `libvirt-nss`
- `libvirt-ssh-proxy`
- `virt-manager`
- `cockpit-machines`
- `cockpit-ostree`
- `podman-compose`
- `podman-machine`
- `podman-tui`

Removed when present:
- `steam`
- `lutris`
- `umu-launcher`
- `winetricks`
- `gamescope`
- `gamescope-libs`
- `gamescope-shaders`
- `mangohud`
- `vkBasalt`
- `steamdeck-backgrounds`
- `steamdeck-gnome-presets`

Intentionally kept:
- Bazzite GNOME base behavior
- Bazzite hardware and peripheral support, including the stack needed for `xone`
- Bazzite-specific repo wiring and low-level services

## Build and Publish

This repository is based on `ublue-os/image-template`.
The bootstrap in [`Containerfile`](./Containerfile) installs `nu` first, then runs the main customization logic from [`build_files/build.nu`](./build_files/build.nu).

The main workflow publishes:
- `ghcr.io/<owner>/bazzite-workstation:testing`
- dated `testing` tags

Before enabling public consumption, set up cosign signing:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
gh secret set SIGNING_SECRET < cosign.key
```

Then enable GitHub Actions for the repository.

## Rebase

From an existing bootc / rpm-ostree system:

```bash
sudo bootc switch ghcr.io/<owner>/bazzite-workstation:testing
```

Fallback:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/<owner>/bazzite-workstation:testing
```

## Local Build

This repository uses environment-scoped `mise` configs:
- `mise.toml` (base tools + shared tasks)
- `mise.development.toml` (local maintainer tasks from `mise-tasks/dev`)
- `mise.ci.toml` (CI/container tasks from `build_files` only)

To enable maintainer tasks locally, create an untracked `.miserc.toml`:

```toml
env = ["development"]
```

Dev maintainer tasks are loaded when `MISE_ENV=development` via `mise.development.toml`.
Container builds force `MISE_ENV=ci`, which loads `mise.ci.toml` and only exposes `build_files` tasks.
You can also run one-off commands with `MISE_ENV=development`.

```bash
mise run build
```

The CI workflow still uses `buildah-build` directly for image publication. `mise` is the local task interface, not the GHCR publishing mechanism.

## Validation Checklist

After rebasing, verify:

```bash
nu --version
micro --version
rpm -q steam lutris gamescope mangohud vkBasalt
```

Also confirm your normal Bazzite hardware workflow still works, especially:
- Xbox wireless adapter support
- Razer support
- GNOME session stability
- `incus version`
- `docker version`
- `virsh list --all`

## Package Policy

This image uses a moderate trim policy:
- remove clearly gaming-oriented desktop applications and overlays
- keep the Bazzite low-level base intact
- avoid broad removals that would make the image diverge sharply from upstream Bazzite

This image intentionally does not add:
- `zsh`
- `code`
- full Bluefin DX userland parity
