#!/usr/bin/env nu
#MISE description="Lint: Check all Nushell task files for syntax errors"
def main [] {
    let tasks = (glob "build_files/**/*.nu") ++ (glob "mise-tasks/**/*.nu")
    let failed = ($tasks | each { |task|
        let result = (^nu --ide-check 0 $task | complete)
        if $result.exit_code != 0 {
            print $"FAILED: ($task)"
            print $result.stderr
            $task
        } else {
            print $"OK: ($task)"
            null
        }
    } | compact)
    if not ($failed | is-empty) { error make {
        msg: $"(($failed | length)) file(s) failed syntax check"
    } }
    print $"All ($tasks | length) task files passed syntax check."
}
