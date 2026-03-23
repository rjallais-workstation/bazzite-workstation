#!/usr/bin/env nu
#MISE description="VM: Run QEMU from raw image"
def main [] { ^mise run run-vm raw disk_config/disk.toml }
