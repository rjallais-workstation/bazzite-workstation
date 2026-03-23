#!/usr/bin/env nu
#MISE description="Format: Run nufmt on all Nushell task files"
def main [--check(-c)] {
    let tasks = (glob "build_files/**/*.nu") ++ (glob "mise-tasks/**/*.nu")
    if $check {
        let failed = ($tasks | each { |task|
            let result = (^nufmt --dry-run $task | complete)
            if $result.exit_code != 0 {
                print $"FAILED: ($task)"
                print $"  ($result.stderr)"
                $task
            } else {
                print $"OK: ($task)"
                null
            }
        } | compact)
        if not ($failed | is-empty) { error make {
            msg: $"($failed | length) file(s) need formatting. Run 'mise run format' to fix."
        } }
    } else {
        for task in $tasks {
            let result = (^nufmt $task | complete)
            if $result.exit_code == 0 { print $"FORMATTED: ($task)" } else {
                print $"ERROR: ($task)"
                print $"  ($result.stderr)"
            }
        }
    }
    print $"Checked ($tasks | length) task files."
}
