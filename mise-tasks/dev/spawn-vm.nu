#!/usr/bin/env nu
#MISE description="VM: Run via systemd-vmspawn"
def main [
    type: string = "qcow2"   # Image type (qcow2, raw, iso)
    ram: string = "6G"        # RAM allocation
    rebuild: int = 0          # Rebuild before running (0 or 1)
] {
    if $rebuild == 1 {
        print $"Rebuilding ($type) image..."
        ^mise run build-$type
    }
    let output_dir = ($env | get -o PWD | default (pwd))
    # Find the image file
    let image_files = (ls $"($output_dir)/output/**/*.($type)" | get name)
    let image_file = if ($image_files | is-empty) {
        print $"No ($type) image found. Build it first with: mise run build-($type)"
        exit 1
    } else { $image_files.0 }
    ^systemd-vmspawn
    -M "bootc-image" 
    --console=gui
    --cpus=2
    --ram=(^numfmt --from=iec $ram | complete).stdout | str trim
    --network-user-mode
    --vsock=false
    --pass-ssh-key=false
    -i $image_file 
}
