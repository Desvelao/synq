#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
README_FILE="$ROOT_DIR/README.md"

usage() {
    echo "Usage: $0 <version>"
    echo "Example: $0 0.0.2-alpha1"
    echo "Example: $0 v0.0.2-alpha1"
}

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

raw_version="$1"
version="${raw_version#v}"

if [[ -z "$version" ]]; then
    echo "Error: version cannot be empty."
    exit 1
fi

if [[ ! "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]; then
    echo "Error: invalid version '$raw_version'."
    echo "Allowed characters: letters, numbers, dot (.), underscore (_), and dash (-)."
    exit 1
fi

tag="v$version"
archive="synq-$version-linux-amd64.tar.gz"

if [[ ! -f "$README_FILE" ]]; then
    echo "Error: README file not found at $README_FILE"
    exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

perl -pe "
  s#/download/v[^/]+/#/download/$tag/#g;
  s#/refs/tags/v[^/]+/#/refs/tags/$tag/#g;
  s#synq-[^/\\s]+-linux-amd64\\.tar\\.gz#$archive#g
" "$README_FILE" > "$tmp_file"

if cmp -s "$README_FILE" "$tmp_file"; then
    echo "No changes made. Installation command is already up to date."
    exit 0
fi

mv "$tmp_file" "$README_FILE"
echo "Updated README installation command to version: $tag"