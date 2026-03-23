#!/usr/bin/env nu
#MISE description="Clean: Remove local build artifacts"
def main [] {
    ^touch _build
    ^find . -maxdepth 1 -name '*_build*' -exec rm -rf '{}' '+'
    ^rm -f previous.manifest.json changelog.md output.env
    ^rm -rf output/
}
