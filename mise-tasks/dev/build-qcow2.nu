#!/usr/bin/env nu
#MISE description="Build: Disk image (qcow2, iso, or raw) from container image"
def main [] {
    let image_name = ($env | get -o IMAGE_NAME | default "bazzite-workstation")
    let default_tag = ($env | get -o DEFAULT_TAG | default "testing")
    let bib_image = ($env | get -o BIB_IMAGE | default "quay.io/centos-bootc/bootc-image-builder:latest")
    let target_image = ($env | get -o TARGET_IMAGE | default $"localhost/($image_name)")
    let tag = ($env | get -o TAG | default $default_tag)
    let config = ($env | get -o CONFIG | default "disk_config/disk.toml")
    let type = ($env | get -o TYPE | default "qcow2")
    let cwd = ($env | get -o PWD | default (pwd))
    let exists = (^sudo podman image exists $"($target_image):($tag)" | complete)
    if $exists.exit_code != 0 {
        let pull_target = (^sudo podman pull $"($target_image):($tag)" | complete)
        if $pull_target.exit_code != 0 { ^sudo podman pull $"localhost/($image_name):($tag)" }
    }
    let buildtmp = (^mktemp -p $cwd -d -t _build-bib.XXXXXXXXXX | complete).stdout | str trim
    ^sudo podman run
    --rm
    -it
    --privileged
    --pull=newer
    --net=host
    --security-opt label=type:unconfined_t 
    -v $"($cwd)/($config):/config.toml:ro" 
    -v $"($buildtmp):/output" 
    -v /var/lib/containers/storage:/var/lib/containers/storage 
    $bib_image
    --type $type 
    --use-librepo=True
    --rootfs=btrfs
    $"($target_image):($tag)"
    ^mkdir -p output
    ^sudo sh -c $"mv -f ($buildtmp)/* output/"
    ^sudo rmdir $buildtmp
    ^sudo chown -R $"($env.USER):($env.USER)" output/
}
