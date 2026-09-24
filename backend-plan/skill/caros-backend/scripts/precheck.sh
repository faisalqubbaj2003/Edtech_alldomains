#!/usr/bin/env bash
# precheck.sh: a fast local mirror of the CAROS backend's CI and hooks,
# run at the end of a session (mode 3). It reads the branch's changes against
# main, including uncommitted and untracked files, and reports what a text
# search can see. CI is the real gate; this only finds problems sooner.
#
# Usage: bash precheck.sh [--base <ref>] [--blocklist <file>] [--chore]
#   --base       compare against this ref (default: origin/main, else main)
#   --blocklist  real-names blocklist, one name per line (default: the first
#                tracked file whose path contains "real-names")
#   --chore      the PR is labelled chore, so docs/PLAN.md need not change
# Exit status: 0 no failures (warnings allowed), 1 at least one failure, 2 usage.
# Written for bash 3.2 (macOS): no associative arrays, no mapfile.

set -u
BASE_REF=""; BLOCKLIST=""; CHORE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE_REF="${2:-}"; shift 2 ;;
    --blocklist) BLOCKLIST="${2:-}"; shift 2 ;;
    --chore) CHORE=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "precheck: unknown argument $1" >&2; exit 2 ;;
  esac
done

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "precheck: not inside a git repository" >&2; exit 2; }
cd "$ROOT" || exit 2

if [ -z "$BASE_REF" ]; then
  if git rev-parse --verify -q origin/main >/dev/null; then BASE_REF=origin/main
  elif git rev-parse --verify -q main >/dev/null; then BASE_REF=main
  else echo "precheck: no main or origin/main; pass --base <ref>" >&2; exit 2; fi
fi
MB=$(git merge-base HEAD "$BASE_REF" 2>/dev/null) || { echo "precheck: no merge base with $BASE_REF" >&2; exit 2; }

FAILS=0; WARNS=0
fail() { FAILS=$((FAILS+1)); printf 'FAIL  %s\n' "$1"; }
warn() { WARNS=$((WARNS+1)); printf 'WARN  %s\n' "$1"; }

# Changed files as "STATUS<TAB>PATH" (renames reported under the new path),
# plus untracked files as additions.
CHANGES=$(git diff --name-status -M "$MB" | awk -F'\t' '{ if ($1 ~ /^R/) print "R\t" $3; else print substr($1,1,1) "\t" $2 }')
UNTRACKED=$(git ls-files --others --exclude-standard)
if [ -n "$UNTRACKED" ]; then
  CHANGES=$(printf '%s\n%s' "$CHANGES" "$(printf '%s\n' "$UNTRACKED" | sed 's/^/A\t/')")
fi
CHANGES=$(printf '%s\n' "$CHANGES" | sed '/^$/d')

if [ -z "$CHANGES" ]; then echo "precheck: no changes against $BASE_REF"; exit 0; fi

# Lines this branch adds to a file (the whole file if it is untracked).
added_lines() {
  if git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; then
    git diff -U0 "$MB" -- "$1" | grep '^+' | grep -v '^+++'
  elif [ -f "$1" ]; then
    sed 's/^/+/' "$1"
  fi
}

# Tests, fixtures and the frozen spec may legitimately contain the strings the
# source must not (a test asserting "no ADEK string" contains "ADEK").
is_exempt() {
  case "$1" in
    docs/spec/*|docs/generated/*|.claude/*|*/test/*|*/tests/*|*/__tests__/*|*.spec.*|*.test.*|*/fixtures/*|*/scenarios/*|*/evals/*) return 0 ;;
  esac
  return 1
}

touched_plan=0; touched_code=0
printf 'precheck: comparing against %s (merge base %s)\n\n' "$BASE_REF" "$(git rev-parse --short "$MB")"

while IFS="$(printf '\t')" read -r status path; do
  [ -z "$path" ] && continue
  case "$path" in docs/PLAN.md) touched_plan=1 ;; packages/*|apps/*) touched_code=1 ;; esac

  # 1. A migration that already exists on main is immutable.
  case "$path" in
    packages/db/migrations/*)
      if [ "$status" != "A" ] && git cat-file -e "$MB:$path" 2>/dev/null; then
        fail "$path: edits a migration that is already on main; a correction is a new migration"
      fi ;;
  esac

  # 2. Generated files are regenerated, never edited.
  case "$path" in docs/generated/*|packages/db/migrations/meta/*)
    fail "$path: generated file changed by hand; regenerate it instead" ;; esac

  [ "$status" = "D" ] && continue
  ADDED=$(added_lines "$path")
  [ -z "$ADDED" ] && continue

  # 3. The engine is pure.
  case "$path" in
    packages/engine/src/*)
      if ! is_exempt "$path"; then
        hit=$(printf '%s\n' "$ADDED" | grep -nE 'Date\.now\(|new Date\(|Math\.random\(|from +["'"'"'](pg|fs|node:[a-z]+|drizzle-orm[^"'"'"']*|@caros/db)["'"'"']' | head -3)
        [ -n "$hit" ] && fail "$path: impure code in packages/engine (clock, randomness, I/O or database): $(printf '%s' "$hit" | tr '\n' ' ' | cut -c1-160)"
      fi ;;
  esac

  # 4. ACS-shaped literals in source (Wellesmere must pass the same code).
  if ! is_exempt "$path"; then
    case "$path" in
      *.ts|*.tsx|*.js|*.jsx|*.sql|*.json)
        hit=$(printf '%s\n' "$ADDED" | grep -nE '\bGrade [0-9]{1,2}\b|Child Protection Officer|Designated Safeguarding Lead|\bADEK\b|\bKHDA\b|American Community School|ACS Abu Dhabi' | head -3)
        [ -n "$hit" ] && warn "$path: school-specific literal; read it from the tenant or its regulator profile: $(printf '%s' "$hit" | tr '\n' ' ' | cut -c1-160)" ;;
    esac
  fi

  # 5. Copy is written to be read aloud: no em dashes.
  case "$path" in
    docs/spec/*|docs/generated/*) ;;
    *.md|*.mdx|*.tsx)
      n=$(printf '%s\n' "$ADDED" | grep -c "$(printf '\342\200\224')")
      [ "$n" -gt 0 ] && warn "$path: $n added line(s) contain an em dash" ;;
  esac

  # 6. Many small files, one concern each.
  if [ -f "$path" ] && ! is_exempt "$path"; then
    lines=$(wc -l < "$path" | tr -d ' ')
    [ "$lines" -gt 800 ] && warn "$path: $lines lines; the repository keeps files under 800"
  fi

  # 7. Wholesale replacement: the failure that cost the prototype four phases.
  if [ "$status" = "M" ] && git cat-file -e "$MB:$path" 2>/dev/null; then
    base_lines=$(git show "$MB:$path" | wc -l | tr -d ' ')
    if [ "$base_lines" -gt 200 ]; then
      deleted=$(git diff --numstat "$MB" -- "$path" | awk '{print $2}')
      case "$deleted" in ''|-) deleted=0 ;; esac
      if [ $((deleted * 100)) -gt $((base_lines * 60)) ]; then
        warn "$path: $deleted of $base_lines lines replaced; CI fails this without a human-applied wholesale-rewrite label"
      fi
    fi
  fi
done <<EOF
$CHANGES
EOF

# 8. The plan moves with the code.
if [ "$touched_code" -eq 1 ] && [ "$touched_plan" -eq 0 ] && [ "$CHORE" -eq 0 ]; then
  fail "docs/PLAN.md: code changed but the plan did not; update the task line and add a session note"
fi

# 9. No real person's name anywhere in the change.
if [ -z "$BLOCKLIST" ]; then
  BLOCKLIST=$(git ls-files | grep -i 'real-names' | head -1)
fi
if [ -n "$BLOCKLIST" ] && [ -f "$BLOCKLIST" ]; then
  while IFS= read -r name; do
    name=$(printf '%s' "$name" | sed 's/[[:space:]]*$//')
    case "$name" in ''|'#'*) continue ;; esac
    while IFS="$(printf '\t')" read -r status path; do
      [ -z "$path" ] || [ "$status" = "D" ] || [ "$path" = "$BLOCKLIST" ] && continue
      if added_lines "$path" | grep -qiF -- "$name"; then
        fail "$path: contains a name on the real-names blocklist; remove it and say so in the PR (the name is not printed here)"
      fi
    done <<EOF2
$CHANGES
EOF2
  done < "$BLOCKLIST"
else
  printf 'NOTE  no real-names blocklist found; that check was skipped\n'
fi

printf '\nprecheck: %d failure(s), %d warning(s)\n' "$FAILS" "$WARNS"
[ "$FAILS" -eq 0 ] || exit 1
exit 0
