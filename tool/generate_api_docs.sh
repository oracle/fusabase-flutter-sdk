#!/usr/bin/env sh

set -eu

dart run dartdoc

# Dartdoc retains the README image URL but does not copy package assets.
# Place the logo at the relative URL used by the generated index page.
mkdir -p doc/api/assets
cp assets/fusabase-color.svg doc/api/assets/fusabase-color.svg
