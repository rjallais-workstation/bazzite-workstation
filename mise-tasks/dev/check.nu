#!/usr/bin/env nu
#MISE description="Check: Validate mise task files (syntax + structure)"
def main [] {
    let nu_tasks = (glob "build_files/**/*.nu")
    let build_results = ($nu_tasks | each { |task|
        let result = (^nu --ide-check 0 $task | complete)
        if $result.exit_code != 0 {
            print $"NUSHELL FAILED: ($task)"
            print $"  ($result.stderr | lines | first 3 | str join (char nl))"
            {file: $task, reason: "nu syntax error"}
        } else {
            print $"NUSHELL OK: ($task)"
            null
        }
    } | compact)
    let dev_tasks = (glob "mise-tasks/**/*.nu")
    let dev_results = ($dev_tasks | each { |task|
        let result = (^nu --ide-check 0 $task | complete)
        if $result.exit_code != 0 {
            print $"NUSHELL FAILED: ($task)"
            print $"  ($result.stderr | lines | first 3 | str join (char nl))"
            {file: $task, reason: "nu syntax error"}
        } else {
            print $"NUSHELL OK: ($task)"
            null
        }
    } | compact)
    # Check mise.toml exists and has [tools]
    let mise_results = if ("mise.toml" | path exists) {
        let root = (open mise.toml)
        if ("tools" in ($root | columns)) {
            print $"MISE OK: mise.toml has [tools]"
            []
        } else {
            print "MISE FAILED: mise.toml missing [tools]"
            [
                {file: "mise.toml", reason: "missing [tools]"}
            ]
        }
    } else { [] }
    let failed = ($build_results ++ $dev_results ++ $mise_results)
    if ($failed | is-empty) { print $"\nAll checks passed." } else { error make {
        msg: $"($failed | length) check(s) failed"
    } }
}
