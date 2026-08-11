#!/usr/bin/env bash
set -euo pipefail

: "${GITLAB_PAT:?Set GITLAB_PAT}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
GITLAB_IP="$(terraform -chdir="${PROJECT_DIR}/infrastructure" output -raw gitlab_public_ip)"
GITLAB_URL="http://${GITLAB_IP}"
APP_DIR="${PROJECT_DIR}/app"
REMOTE_URL="${GITLAB_URL}/root/step-project-3.git"
PUSH_URL="http://root:${GITLAB_PAT}@${GITLAB_IP}/root/step-project-3.git"

cd "${APP_DIR}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "${REMOTE_URL}"
else
  git remote add origin "${REMOTE_URL}"
fi

if git show-ref --verify --quiet refs/heads/main; then
  git switch main
elif git rev-parse --verify --quiet HEAD >/dev/null; then
  git branch -M main
else
  git switch -c main
fi

git add .
if ! git diff --cached --quiet; then
  git commit -m "Initial commit"
fi

git -c remote.origin.url="${PUSH_URL}" push -u origin main
