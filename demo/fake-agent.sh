#!/usr/bin/env bash
# Pretends to be an AI coding agent: prints colorful output, then waits at its prompt.
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
r=$'\e[0m' b=$'\e[1m' gray=$'\e[90m' mauve=$'\e[38;2;203;166;247m'
echo "${mauve}${b}agent${r} ${gray}| fix the ANSI renderer and run the tests${r}"
echo
"$dir/sample-output.sh"
echo
echo "${mauve}${b}agent${r} Two tests still fail. Should I keep going?"
echo
echo "${gray}-------------------------------------------------- message --${r}"
printf '%s ' "${mauve}${b}>${r}"
exec cat > /dev/null
