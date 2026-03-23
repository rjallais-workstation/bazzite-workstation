#!/usr/bin/env nu
#MISE description="Build: Raw disk image from local container image"
def main [] { with-env { TYPE: "raw" } {
        ^mise run build-qcow2
    } }
