#!/usr/bin/env bash
# Prints colorful, deterministic output for the demo recording.
rev=$'\e[7m' r=$'\e[0m' b=$'\e[1m' i=$'\e[3m' u=$'\e[4m' s=$'\e[9m'
red=$'\e[31m' green=$'\e[32m' yellow=$'\e[33m' blue=$'\e[34m' cyan=$'\e[36m' gray=$'\e[90m'
orange=$'\e[38;5;208m' pink=$'\e[38;2;245;169;184m'

echo "${b}${blue}==>${r} ${b}Running test suite${r} ${gray}(12 files)${r}"
echo
echo " ${green}PASS${r} parser/tokenize.spec.ts ${gray}(18 tests)${r} ${gray}42ms${r}"
echo " ${green}PASS${r} parser/ast.spec.ts ${gray}(31 tests)${r} ${gray}57ms${r}"
echo " ${green}PASS${r} render/ansi.spec.ts ${gray}(24 tests)${r} ${gray}39ms${r}"
echo " ${red}FAIL${r} render/highlight.spec.ts ${gray}(9 tests | ${red}2 failed${gray})${r}"
echo "   ${red}${b}x${r} keeps bold when reset is partial"
echo "     ${gray}expected${r} ${green}\"${b}bold${r}${green}\"${r} ${gray}received${r} ${red}\"plain\"${r}"
echo "   ${red}${b}x${r} maps 256-color palette ${orange}index 208${r}"
echo " ${yellow}SKIP${r} cli/args.spec.ts ${gray}(1 skipped)${r} ${i}flaky on CI${r}"
echo " ${green}PASS${r} util/strings.spec.ts ${gray}(12 tests)${r} ${gray}8ms${r}"
echo
echo "${b}Tests${r}  ${red}2 failed${r} | ${green}92 passed${r} | ${yellow}1 skipped${r}"
echo "${b}Styles${r} ${b}bold${r} ${i}italic${r} ${u}underline${r} ${s}strike${r} ${rev}reverse${r} ${pink}rgb${r} ${cyan}cyan${r}"
