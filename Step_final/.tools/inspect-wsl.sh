#!/usr/bin/env bash
ps -eo pid,comm,etime | grep -E 'unzip|curl|install|aws|cp' || true
ls -l /home/gf/.local/bin/aws || true
bash -n "$(dirname "${BASH_SOURCE[0]}")/../project/scripts/project.sh"
