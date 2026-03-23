#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

collect_pairs() {
  if [ -d "$REPO_ROOT/config" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/config/"}"
      printf '%s\t%s\n' "$src" "$HOME/.config/$rel"
    done < <(find "$REPO_ROOT/config" \( -type f -o -type l \) | sort)
  fi

  if [ -d "$REPO_ROOT/local/bin" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/local/bin/"}"
      printf '%s\t%s\n' "$src" "$HOME/.local/bin/$rel"
    done < <(find "$REPO_ROOT/local/bin" \( -type f -o -type l \) | sort)
  fi

  if [ -d "$REPO_ROOT/bin" ]; then
    while IFS= read -r src; do
      rel="${src#"$REPO_ROOT/bin/"}"
      printf '%s\t%s\n' "$src" "$HOME/bin/$rel"
    done < <(find "$REPO_ROOT/bin" \( -type f -o -type l \) | sort)
  fi
}

ok=0
missing=0
conflict=0
drift=0
source_missing=0

while IFS=$'\t' read -r source target; do
  [ -n "$source" ] || continue

  if [ ! -e "$source" ] && [ ! -L "$source" ]; then
    echo "SOURCE_MISSING $source"
    source_missing=$((source_missing + 1))
    continue
  fi

  if [ -L "$target" ]; then
    linked="$(readlink -f "$target" 2>/dev/null || true)"
    expected="$(readlink -f "$source" 2>/dev/null || true)"
    if [ -n "$linked" ] && [ "$linked" = "$expected" ]; then
      echo "OK $target"
      ok=$((ok + 1))
    else
      echo "DRIFT $target -> $(readlink "$target")"
      drift=$((drift + 1))
    fi
    continue
  fi

  if [ -e "$target" ]; then
    echo "CONFLICT $target"
    conflict=$((conflict + 1))
  else
    echo "MISSING $target"
    missing=$((missing + 1))
  fi
done < <(collect_pairs)

echo
echo "Summary: ok=$ok missing=$missing conflict=$conflict drift=$drift source_missing=$source_missing"

if [ "$missing" -gt 0 ] || [ "$conflict" -gt 0 ] || [ "$drift" -gt 0 ] || [ "$source_missing" -gt 0 ]; then
  exit 1
fi
