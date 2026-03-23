#!/usr/bin/env nu
#MISE description="Rebuild: Container image then build raw disk"
def main [] { with-env { IMAGE_NAME: ($env | get -o IMAGE_NAME | default "bazzite-workstation") } {
        ^mise run build
        with-env { TYPE: "raw", CONFIG: "disk_config/disk.toml" } {
            ^mise run build-qcow2
        }
    } }
