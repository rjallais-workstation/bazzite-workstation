#!/usr/bin/env nu
#MISE description="Build: Container image for local testing"
def main [] {
    let image_name = ($env | get -o IMAGE_NAME | default "bazzite-workstation")
    let default_tag = ($env | get -o DEFAULT_TAG | default "testing")
    let git_status = (^git status -s | complete)
    let build_args = if ($git_status.stdout | str trim | is-empty) {
        let sha = (^git rev-parse --short HEAD | complete)
        [
            "--build-arg"
            $"SHA_HEAD_SHORT=($sha.stdout | str trim)"
        ]
    } else { [] }
    ^podman build ...$build_args --pull=newer --tag $"localhost/($image_name):($default_tag)" .
}
