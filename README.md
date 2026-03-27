# bazzite-workstation

Custom Universal Blue image built on top of `ghcr.io/ublue-os/bazzite-gnome:testing`.

This image keeps Bazzite's GNOME desktop and low-level hardware stack, trims the most obvious gaming-oriented desktop packages, and adds workstation/developer host tooling without changing your shell or IDE choice:
- `nushell`
- `Incus`
- `Docker`
- `libvirt` / `virt-manager`
- `cockpit-machines`
- Podman helper tools

## Community

If you have questions, try the following spaces:
- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions)

## What Changes

Base image:
- `ghcr.io/ublue-os/bazzite-gnome:testing`

Added host packages:
- `nushell`
- `incus`
- `incus-agent`
- `incus-client`
- `incus-selinux`
- `docker-ce`
- `docker-ce-cli`
- `docker-buildx-plugin`
- `docker-compose-plugin`
- `docker-model-plugin`
- `libvirt-daemon-kvm`
- `libvirt-dbus`
- `libvirt-glib`
- `libvirt-nss`
- `libvirt-ssh-proxy`
- `virt-manager`
- `virt-viewer`
- `cockpit-machines`
- `cockpit-ostree`
- `podman-compose`
- `podman-machine`
- `podman-tui`

Removed when present:
- `steam`
- `lutris`
- `umu-launcher`
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

## Step 0: Prerequisites

These steps assume you have the following:
- A Github Account
- A machine running a bootc image (e.g. Bazzite, Bluefin, Aurora, or Fedora Atomic)
- Experience installing and using CLI programs

## Step 1: Preparing the Template

### Step 1a: Copying the Template

Select `Use this Template` on this page. You can set the name and description of your repository to whatever you would like, but all other settings should be left untouched.

Once you have finished copying the template, you need to enable the Github Actions workflows for your new repository.
To enable the workflows, go to the `Actions` tab of the new repository and click the button to enable workflows.

### Step 1b: Cloning the New Repository

Here I will defer to the much superior GitHub documentation on the matter. You can use whichever method is easiest.
[GitHub Documentation](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)

Once you have the repository on your local drive, proceed to the next step.

## Step 2: Initial Setup

### Step 2a: Creating a Cosign Key

Container signing is important for end-user security and is enabled on all Universal Blue images. By default the image builds *will fail* if you don't.

First, install the [cosign CLI tool](https://edu.chainguard.dev/open-source/sigstore/cosign/how-to-install-cosign/#installing-cosign-with-the-cosign-binary)
With the cosign tool installed, run inside your repo folder:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
```

The signing key will be used in GitHub Actions and will not work if it is password protected.

> [!WARNING]
> Be careful to *never* accidentally commit `cosign.key` into your git repo. If this key goes out to the public, the security of your repository is compromised.

Next, you need to add the key to GitHub. This makes use of GitHub's secret signing system.

<details>
    <summary>Using the Github Web Interface (preferred)</summary>

Go to your repository settings, under `Secrets and Variables` -> `Actions`
![image](https://user-images.githubusercontent.com/1264109/216735595-0ecf1b66-b9ee-439e-87d7-c8cc43c2110a.png)
Add a new secret and name it `SIGNING_SECRET`, then paste the contents of `cosign.key` into the secret and save it. Make sure it's the .key file and not the .pub file. Once done, it should look like this:
![image](https://user-images.githubusercontent.com/1264109/216735690-2d19271f-cee2-45ac-a039-23e6a4c16b34.png)
</details>
<details>
<summary>Using the Github CLI</summary>

If you have the `github-cli` installed, run:

```bash
gh secret set SIGNING_SECRET < cosign.key
```
</details>

### Step 2b: Choosing Your Base Image

This image uses `ghcr.io/ublue-os/bazzite-gnome:${DEFAULT_TAG}` as its base. To switch between `stable` and `testing`, update the `DEFAULT_TAG` value used for your build. The [Containerfile](./Containerfile) now templates the base image tag from that value instead of hardcoding it in `FROM`.

### Step 2c: Initial Commit

To commit and push all the files changed and added in step 2 into your Github repository:
```bash
git add Containerfile mise.toml mise.ci.toml cosign.pub
git commit -m "Initial Setup"
git push
```
Once pushed, go look at the Actions tab on your Github repository's page.  The green checkmark should be showing on the top commit, which means your new image is ready!

## Step 3: Switch to Your Image

From your bootc system, run the following command substituting in your Github username and image name where noted.
```bash
sudo bootc switch ghcr.io/<username>/bazzite-workstation:testing
```
This should queue your image for the next reboot, which you can do immediately after the command finishes. You have officially set up your custom image!

## Build and Publish

This repository is based on `ublue-os/image-template`.
The bootstrap in [`Containerfile`](./Containerfile) installs `nu` first, then runs the main customization logic from [`build_files/install/`](./build_files/install/) tasks.

The main workflow publishes:
- `ghcr.io/<owner>/bazzite-workstation:testing`
- dated `testing` tags

It also generates an SPDX JSON SBOM with Anchore Syft and runs an Anchore Grype vulnerability scan whose SARIF results are published to GitHub code scanning.

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

# Repository Contents

## Containerfile

The [Containerfile](./Containerfile) defines the operations used to customize the selected image. This file is the entrypoint for your image build, and works exactly like a regular podman Containerfile. For reference, please see the [Podman Documentation](https://docs.podman.io/en/latest/Introduction.html).

## build_files/

The [`build_files/`](./build_files/) directory contains Nushell task scripts called from the Containerfile. Each subdirectory groups related tasks:
- `build_files/install/` - Package installation tasks
- `build_files/prepare/` - Repository and service configuration
- `build_files/finalize/` - Linting and cleanup
- `build_files/etc/` and `build_files/usr/` - System configuration files

## mise.toml / mise.ci.toml

This project uses [mise](https://mise.jdx.dev/) for task management:
- `mise.toml` - Base configuration with tools and bootstrap task
- `mise.ci.toml` - CI-specific configuration (includes `build_files` tasks only)

## build.yml

The [build.yml](./.github/workflows/build.yml) Github Actions workflow creates your custom OCI image and publishes it to the Github Container Registry (GHCR). By default, the image name will match the Github repository name. There are several environment variables at the start of the workflow which may be of interest to change.

# Building Disk Images

This template provides an out of the box workflow for creating disk images (ISO, qcow2, raw) for your custom OCI image which can be used to directly install onto your machines.

This template provides a way to upload the disk images that is generated from the workflow to a S3 bucket. The disk images will also be available as an artifact from the job, if you wish to use an alternate provider. To upload to S3 we use [rclone](https://rclone.org/) which is able to use [many S3 providers](https://rclone.org/s3/).

## Setting Up ISO Builds

The [build-disk.yml](./.github/workflows/build-disk.yml) Github Actions workflow creates a disk image from your OCI image by utilizing the [bootc-image-builder](https://osbuild.org/docs/bootc/). In order to use this workflow you must complete the following steps:

1. Modify `disk_config/iso.toml` to point to your custom container image before generating an ISO image.
2. If you changed your image name from the default in `build.yml` then in the `build-disk.yml` file edit the `IMAGE_REGISTRY`, `IMAGE_NAME` and `DEFAULT_TAG` environment variables with the correct values. If you did not make changes, skip this step.
3. Finally, if you want to upload your disk images to S3 then you will need to add your S3 configuration to the repository's Action secrets. This can be found by going to your repository settings, under `Secrets and Variables` -> `Actions`. You will need to add the following
  - `S3_PROVIDER` - Must match one of the values from the [supported list](https://rclone.org/s3/)
  - `S3_BUCKET_NAME` - Your unique bucket name
  - `S3_ACCESS_KEY_ID` - It is recommended that you make a separate key just for this workflow
  - `S3_SECRET_ACCESS_KEY` - See above.
  - `S3_REGION` - The region your bucket lives in. If you do not know then set this value to `auto`.
  - `S3_ENDPOINT` - This value will be specific to the bucket as well.

Once the workflow is done, you'll find the disk images either in your S3 bucket or as part of the summary under `Artifacts` after the workflow is completed.

# Artifacthub

This template comes with the necessary tooling to index your image on [artifacthub.io](https://artifacthub.io). Use the `artifacthub-repo.yml` file at the root to verify yourself as the publisher. This is important to you for a few reasons:

- The value of artifacthub is it's one place for people to index their custom images, and since we depend on each other to learn, it helps grow the community.
- You get to see your pet project listed with the other cool projects in Cloud Native.
- Since the site puts your README front and center, it's a good way to learn how to write a good README, learn some marketing, finding your audience, etc.

[Discussion Thread](https://universal-blue.discourse.group/t/listing-your-custom-image-on-artifacthub/6446)

# Local Build

This repository uses [mise](https://mise.jdx.dev/) for task management:

```bash
mise run build
```

Development tasks are in `mise-tasks/dev/` and are loaded when `MISE_ENV=development` is set:

```bash
MISE_ENV=development mise run build
MISE_ENV=development mise run build-iso
MISE_ENV=development mise run spawn-vm
```

The CI workflow uses `buildah-build` directly for image publication. `mise` is the local task interface, not the GHCR publishing mechanism.

## Available Tasks

| Task | Description |
|------|-------------|
| `mise run build` | Build container image for local testing |
| `mise run build-iso` | Build ISO image |
| `mise run build-qcow2` | Build QCOW2 virtual machine image |
| `mise run build-raw` | Build raw disk image |
| `mise run rebuild-iso` | Rebuild ISO image |
| `mise run rebuild-qcow2` | Rebuild QCOW2 image |
| `mise run rebuild-raw` | Rebuild raw image |
| `mise run run-vm` | Run virtual machine |
| `mise run run-vm-iso` | Run VM from ISO |
| `mise run run-vm-qcow2` | Run VM from QCOW2 |
| `mise run run-vm-raw` | Run VM from raw image |
| `mise run spawn-vm` | Spawn VM using systemd-vmspawn |
| `mise run lint` | Check Nushell task files for syntax errors |
| `mise run format` | Format Nushell task files |
| `mise run check` | Check task file syntax |
| `mise run fix` | Fix task file syntax |
| `mise run clean` | Clean build artifacts |

# Validation Checklist

After rebasing, verify:

```bash
nu --version
rpm -q steam lutris gamescope mangohud vkBasalt
```

Also confirm your normal Bazzite hardware workflow still works, especially:
- Xbox wireless adapter support
- Razer support
- GNOME session stability
- `incus version`
- `docker version`
- `virsh list --all`

# Package Policy

This image uses a moderate trim policy:
- remove clearly gaming-oriented desktop applications and overlays
- keep the Bazzite low-level base intact
- avoid broad removals that would make the image diverge sharply from upstream Bazzite

This image intentionally does not add:
- `zsh`
- `code`
- full Bluefin DX userland parity

# Additional Resources

For additional driver support, ublue maintains a set of scripts and container images available at [ublue-akmod](https://github.com/ublue-os/akmods). These images include the necessary scripts to install multiple kernel drivers within the container (Nvidia, OpenRazer, Framework...). The documentation provides guidance on how to properly integrate these drivers into your container image.

# Community Examples

These are images derived from this template (or similar enough to this template). Reference them when building your image!

- [m2Giles' OS](https://github.com/m2giles/m2os)
- [bOS](https://github.com/bsherman/bos)
- [Homer](https://github.com/bketelsen/homer/)
- [Amy OS](https://github.com/astrovm/amyos)
- [VeneOS](https://github.com/Venefilyn/veneos)
