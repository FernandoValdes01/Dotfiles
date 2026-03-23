#!/usr/bin/env bash
set -euo pipefail

BACKUP_BASE="${DOTFILES_BACKUP_ROOT:-$HOME/dotfiles-backups}"
BACKUP_DIR=""
FORCE=0

usage() {
  cat <<'EOF'
Usage: ./restore.sh [--backup DIR] [--force] [path ...]

Restores files from a backup manifest created by migration, install or
backup-originals.sh. Without --backup, the latest backup directory is used.
Optional selectors may be absolute target paths, paths relative to $HOME,
or repo-relative paths like config/hypr/autostart.conf.
EOF
}

latest_backup_dir() {
  find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1
}

matches_selector() {
  local original="$1"
  local repo_path="$2"
  shift 2 || true

  if [ "$#" -eq 0 ]; then
    return 0
  fi

  local selector home_rel repo_rel
  home_rel="${original#"$HOME/"}"
  repo_rel="${repo_path#"$HOME/dotfiles/"}"
  for selector in "$@"; do
    if [ "$selector" = "$original" ] || [ "$selector" = "$home_rel" ] || [ "$selector" = "$repo_rel" ]; then
      return 0
    fi
  done

  return 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --backup)
      BACKUP_DIR="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR="$(latest_backup_dir)"
fi

if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
  echo "Backup directory not found" >&2
  exit 1
fi

MANIFEST="$BACKUP_DIR/manifest.tsv"
if [ ! -f "$MANIFEST" ]; then
  echo "Manifest not found: $MANIFEST" >&2
  exit 1
fi

LOG_FILE="$BACKUP_DIR/restore-$(date +%Y%m%dT%H%M%S%z).log"
PREEXISTING_DIR="$BACKUP_DIR/restore-preexisting"
selected=0
restored=0

{
  echo "Restore started at $(date --iso-8601=seconds)"
  echo "Using backup: $BACKUP_DIR"
} > "$LOG_FILE"

while IFS=$'\t' read -r original repo_path backup_path operation kind link_target sha timestamp; do
  [ -n "$original" ] || continue

  if ! matches_selector "$original" "$repo_path" "$@"; then
    continue
  fi

  selected=$((selected + 1))

  if [ ! -e "$backup_path" ] && [ ! -L "$backup_path" ]; then
    echo "Missing backup payload for $original: $backup_path" | tee -a "$LOG_FILE" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$original")"

  if [ -L "$original" ]; then
    echo "Removing symlink $original" | tee -a "$LOG_FILE"
    rm -f "$original"
  elif [ -e "$original" ]; then
    if [ "$FORCE" -ne 1 ]; then
      echo "Refusing to overwrite non-symlink target without --force: $original" | tee -a "$LOG_FILE" >&2
      exit 1
    fi

    preexisting="$PREEXISTING_DIR/${original#"$HOME/"}"
    mkdir -p "$(dirname "$preexisting")"
    mv "$original" "$preexisting"
    echo "Moved preexisting target to $preexisting" | tee -a "$LOG_FILE"
  fi

  cp -a "$backup_path" "$original"
  echo "Restored $original" | tee -a "$LOG_FILE"
  restored=$((restored + 1))
done < <(tail -n +2 "$MANIFEST")

if [ "$selected" -eq 0 ]; then
  echo "No manifest entries matched the requested selectors" | tee -a "$LOG_FILE" >&2
  exit 1
fi

echo "Restore complete: restored=$restored log=$LOG_FILE"
