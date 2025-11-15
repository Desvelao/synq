#!/bin/bash
# This script updates all Jest snapshots in the project.

cmd=(../../synq)

"${cmd[@]}" --help > help.snapshot
"${cmd[@]}" -y --unknown > opt-unknown.snapshot
"${cmd[@]}" -y --version > version.snapshot