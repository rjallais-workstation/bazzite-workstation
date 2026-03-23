#!/usr/bin/env nu
#MISE description="Rebuild: Container image then build ISO"
def main [] { with-env { IMAGE_NAME: ($env | get -o IMAGE_NAME | default "bazzite-workstation") } {
        ^mise run build
        with-env { TYPE: "iso", CONFIG: "disk_config/iso.toml" } {
            ^mise run build-qcow2
        }
    } }
