#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE="${DOTFILES_BACKUP_ROOT:-$HOME/dotfiles-backups}"
TIMESTAMP="$(date +%Y%m%dT%H%M%S%z)"
BACKUP_DIR=""
BACKUP_MANIFEST=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run]

Recreate symlinks from this dotfiles repo into $HOME.
If a target already exists, it is backed up before being replaced.
EOF
}

collect_pairs() {
  if [ -d "$REPO_ROOT/config" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/config/"}"
      printf '%s\t%s\n' "$src" "$HOME/.config/$rel"
    done < <(find "$REPO_ROOT/config" \( -type f -o -type l \) \
      ! -name '*.bak.*' \
      ! -name '*.tmp' \
      ! -name '*.temp' \
      | sort)
  fi

  if [ -d "$REPO_ROOT/local/bin" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/local/bin/"}"
      printf '%s\t%s\n' "$src" "$HOME/.local/bin/$rel"
    done < <(find "$REPO_ROOT/local/bin" \( -type f -o -type l \) \
      ! -name '*.bak.*' \
      ! -name '*.tmp' \
      ! -name '*.temp' \
      | sort)
  fi

  if [ -d "$REPO_ROOT/bin" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/bin/"}"
      printf '%s\t%s\n' "$src" "$HOME/bin/$rel"
    done < <(find "$REPO_ROOT/bin" \( -type f -o -type l \) \
      ! -name '*.bak.*' \
      ! -name '*.tmp' \
      ! -name '*.temp' \
      | sort)
  fi
}

ensure_backup_manifest() {
  if [ -n "$BACKUP_DIR" ]; then
    return
  fi

  BACKUP_DIR="$BACKUP_BASE/install-$TIMESTAMP"
  BACKUP_MANIFEST="$BACKUP_DIR/manifest.tsv"
  mkdir -p "$BACKUP_DIR/originals"
  printf 'original_path\trepo_path\tbackup_path\toperation\toriginal_kind\tsymlink_target\tsha256\ttimestamp\n' > "$BACKUP_MANIFEST"
}

backup_target() {
  local target="$1"
  local source="$2"
  local rel backup_path kind link_target sha

  rel="${target#"$HOME/"}"
  backup_path="$BACKUP_DIR/originals/$rel"
  if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
    return
  fi

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
    "$target" "$source" "$backup_path" "install_relink" "$kind" "$link_target" "$sha" "$TIMESTAMP" \
    >> "$BACKUP_MANIFEST"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

changed=0

while IFS=$'\t' read -r source target; do
  [ -n "$source" ] || continue

  if [ ! -e "$source" ] && [ ! -L "$source" ]; then
    echo "SOURCE_MISSING $source"
    continue
  fi

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    linked="$(readlink -f "$target" 2>/dev/null || true)"
    expected="$(readlink -f "$source" 2>/dev/null || true)"
    if [ -n "$linked" ] && [ "$linked" = "$expected" ]; then
      echo "OK $target"
      continue
    fi

    echo "RELINK $target"
    if [ "$DRY_RUN" -eq 0 ]; then
      ensure_backup_manifest
      backup_target "$target" "$source"
      rm -f "$target"
      ln -s "$source" "$target"
    fi
    changed=1
    continue
  fi

  if [ -e "$target" ]; then
    if [ -d "$target" ]; then
      echo "SKIP_DIRECTORY $target"
      continue
    fi

    echo "BACKUP_AND_LINK $target"
    if [ "$DRY_RUN" -eq 0 ]; then
      ensure_backup_manifest
      backup_target "$target" "$source"
      rm -f "$target"
      ln -s "$source" "$target"
    fi
    changed=1
    continue
  fi

  echo "LINK $target"
  if [ "$DRY_RUN" -eq 0 ]; then
    ln -s "$source" "$target"
  fi
  changed=1
done < <(collect_pairs)

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY_RUN complete"
elif [ "$changed" -eq 1 ] && [ -n "$BACKUP_DIR" ]; then
  echo "Backup created at $BACKUP_DIR"
else
  echo "Nothing changed"
fi
