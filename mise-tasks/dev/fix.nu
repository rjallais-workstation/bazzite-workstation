#!/usr/bin/env nu
#MISE description="Fix: Run nufmt on all Nushell task files"
def main [] {
    let tasks = (glob "build_files/**/*.nu") ++ (glob "mise-tasks/**/*.nu")
    for task in $tasks {
        let result = (^nufmt $task | complete)
        if $result.exit_code == 0 { print $"FIXED: ($task)" } else {
            print $"ERROR: ($task)"
            print $"  ($result.stderr)"
        }
    }
}
