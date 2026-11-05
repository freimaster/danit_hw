#!/usr/bin/env bash
set -euo pipefail
workspace=/mnt/c/Users/g_fre/Documents/danit_hw/Step_final
source_path="$(realpath "$workspace/test")"
destination_path="$(realpath -m "$workspace/project")"
[[ "$source_path" == "$workspace/test" && "$destination_path" == "$workspace/project" ]]
[[ ! -e "$destination_path" ]]
cd "$workspace"
mv -T -- "$source_path" "$destination_path"
