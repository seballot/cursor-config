#!/usr/bin/env bash
# stop hook: gate agent completion on linters for all uncommitted files.
# Delegates to bin/lint --fix --changed; if offenses remain, asks the agent
# to fix them and the agent loop continues.

set -uo pipefail

input=$(cat)
status=$(printf '%s' "$input" | jq -r '.status // empty')

# Only gate work that the agent considers finished.
[[ "$status" == "completed" ]] || exit 0

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0

set +e
out=$(bin/lint --fix --changed 2>&1)
lint_status=$?
set -e

((lint_status == 0)) && exit 0

report=$out
((${#report} > 4000)) && report="…$(printf '%s' "$report" | tail -c 4000)"

message="The pre-submit lint gate failed. Auto-fixes were applied to uncommitted files, but these offenses remain:

$report

Fix them (run \`bin/lint --fix --changed\` for mechanical ones, edit by hand for the rest). Do not report the task as done until that command is clean."

jq -n --arg message "$message" '{followup_message: $message}'
exit 0
