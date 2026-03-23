#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE="${DOTFILES_BACKUP_ROOT:-$HOME/dotfiles-backups}"
TIMESTAMP="$(date +%Y%m%dT%H%M%S%z)"
BACKUP_DIR="$BACKUP_BASE/manual-$TIMESTAMP"
MANIFEST="$BACKUP_DIR/manifest.tsv"

usage() {
  cat <<'EOF'
Usage: ./backup-originals.sh [path ...]

Without arguments, backs up all managed targets currently present in $HOME.
Optional selectors may be absolute target paths, paths relative to $HOME,
or repo-relative paths like config/hypr/autostart.conf.
EOF
}

collect_pairs() {
  if [ -d "$REPO_ROOT/config" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/config/"}"
      printf '%s\t%s\t%s\n' "$src" "$HOME/.config/$rel" "config/$rel"
    done < <(find "$REPO_ROOT/config" \( -type f -o -type l \) | sort)
  fi

  if [ -d "$REPO_ROOT/local/bin" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/local/bin/"}"
      printf '%s\t%s\t%s\n' "$src" "$HOME/.local/bin/$rel" "local/bin/$rel"
    done < <(find "$REPO_ROOT/local/bin" \( -type f -o -type l \) | sort)
  fi

  if [ -d "$REPO_ROOT/bin" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/bin/"}"
      printf '%s\t%s\t%s\n' "$src" "$HOME/bin/$rel" "bin/$rel"
    done < <(find "$REPO_ROOT/bin" \( -type f -o -type l \) | sort)
  fi
}

matches_selector() {
  local target="$1"
  local repo_rel="$2"
  shift 2 || true

  if [ "$#" -eq 0 ]; then
    return 0
  fi

  local selector home_rel
  home_rel="${target#"$HOME/"}"
  for selector in "$@"; do
    if [ "$selector" = "$target" ] || [ "$selector" = "$home_rel" ] || [ "$selector" = "$repo_rel" ]; then
      return 0
    fi
  done

  return 1
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

mkdir -p "$BACKUP_DIR/originals"
printf 'original_path\trepo_path\tbackup_path\toperation\toriginal_kind\tsymlink_target\tsha256\ttimestamp\n' > "$MANIFEST"

count=0
while IFS=$'\t' read -r source target repo_rel; do
  [ -n "$source" ] || continue

  if ! matches_selector "$target" "$repo_rel" "$@"; then
    continue
  fi

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    echo "SKIP_MISSING $target"
    continue
  fi

  rel="${target#"$HOME/"}"
  backup_path="$BACKUP_DIR/originals/$rel"
  mkdir -p "$(dirname "$backup_path")"
  cp -a "$target" "$backup_path"

  kind="$(stat --format '%F' "$target")"
  link_target=""
  sha="-"
  if [ -L "$target" ]; then
    link_target="$(readlink "$target")"
  else
    sha="$(sha256sum "$target" | awk '{print $1}')"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$target" "$source" "$backup_path" "manual_backup" "$kind" "$link_target" "$sha" "$TIMESTAMP" \
    >> "$MANIFEST"

  echo "BACKED_UP $target"
  count=$((count + 1))
done < <(collect_pairs)

if [ "$count" -eq 0 ]; then
  rm -rf "$BACKUP_DIR"
  echo "No matching managed files were backed up"
  exit 1
fi

echo "Backup created at $BACKUP_DIR"
