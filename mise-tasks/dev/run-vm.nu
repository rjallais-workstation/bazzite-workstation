#!/usr/bin/env nu
#MISE description="VM: Run QEMU from built disk image"
def main [type: string = qcow2, config: string = disk_config/disk.toml] {
    let image_name = ($env | get -o IMAGE_NAME | default "bazzite-workstation")
    let default_tag = ($env | get -o DEFAULT_TAG | default "testing")
    let cwd = ($env | get -o PWD | default (pwd))
    # Determine image file path
    let image_file = if $type == "iso" { $"($cwd)/output/bootiso/install.iso" } else { $"($cwd)/output/($type)/disk.($type)" }
    # Build if image doesn't exist
    if not ($image_file | path exists) {
        if $type == "iso" { ^mise run build-iso } else if $type == "raw" { ^mise run build-raw } else { ^mise run build-qcow2 }
    }
    # Find available port starting from 8006
    let port = (mut p = 8006
    while (^ss -tunalp | complete).stdout =~ $"($p)" { $p = $p + 1 }
    $p)
    print $"Using Port: ($port)"
    print $"Connect to http://localhost:($port)"
    # Run QEMU via podman
    let boot_ext = if $type == "iso" { "iso" } else { $type }
    podman run
    --rm --privileged --pull=newer
    --publish $"127.0.0.1:($port):8006" 
    --env "CPU_CORES=4" 
    --env "RAM_SIZE=8G" 
    --env "DISK_SIZE=64G" 
    --env "TPM=Y" 
    --env "GPU=Y" 
    --device=/dev/kvm
    --volume $"($image_file):/boot.($boot_ext)" 
    docker.io/qemux/qemu
    # Open browser
    try { xdg-open $"http://localhost:($port)" } catch { null }
}
