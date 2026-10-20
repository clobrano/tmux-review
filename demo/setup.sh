#!/usr/bin/env bash
# Clones the Neovim plugins used by demo.tape into demo/.plugins.
set -euo pipefail
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/.plugins"
mkdir -p "$dir"
for repo in georgeguimaraes/review.nvim esmuellert/codediff.nvim MunifTanjim/nui.nvim; do
  [ -d "$dir/${repo#*/}" ] || git clone -q --depth 1 "https://github.com/$repo" "$dir/${repo#*/}"
done
