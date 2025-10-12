#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
BACKUP_DIR="$REPO_ROOT/backup-unused"

TARGETS=(
  "AWSSetup1.png"
  "AWSSetup2.png"
  "AWSSetup3.png"
  "movie-analyst-api;C"
)

mkdir -p "$BACKUP_DIR"

echo "Repository root: $REPO_ROOT"
echo "Backup folder: $BACKUP_DIR"
echo
echo "Will move the following files (if present):"
for t in "${TARGETS[@]}"; do
  echo " - $t"
done

read -r -p $'Type YES to proceed: ' CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted by user. No changes made."
  exit 0
fi

MOVED=()
MISSING=()

for t in "${TARGETS[@]}"; do
  if [[ -e "$REPO_ROOT/$t" ]]; then
    mv -f "$REPO_ROOT/$t" "$BACKUP_DIR/"
    MOVED+=("$t")
    echo "Moved: $t"
  else
    MISSING+=("$t")
    echo "Not found: $t"
  fi
done

echo
echo "Summary:"
echo "Moved files: ${MOVED[*]:-None}"
echo "Missing files: ${MISSING[*]:-None}"

echo
echo "Next steps (recommended):"
echo " 1) Inspect the backup folder: $BACKUP_DIR"
echo " 2) Run 'git status --short' and review changes"
echo " 3) If OK, stage and commit: 'git add -A' then 'git commit -m "chore: remove unused artifacts"'"
