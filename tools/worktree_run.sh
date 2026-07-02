#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
BASE_BRANCH="${BASE_BRANCH:-main}"
REMOTE="${REMOTE:-origin}"
APP_SUBDIR="${APP_SUBDIR:-ludo_club}"
PUSH_ENABLED="${PUSH_ENABLED:-0}"

worktree_dir_in_use() {
  local dir="$1"
  while IFS= read -r line; do
    if [[ "$line" == "worktree "* ]]; then
      local path="${line#worktree }"
      if [[ "$path" == "$dir" ]]; then
        return 0
      fi
    fi
  done < <(git -C "$REPO_ROOT" worktree list --porcelain)
  return 1
}

worktree_path_for_branch() {
  local branch="$1"
  local current_path=""
  while IFS= read -r line; do
    if [[ "$line" == "worktree "* ]]; then
      current_path="${line#worktree }"
    elif [[ "$line" == branch* ]]; then
      local ref="${line#branch }"
      if [[ "$ref" == "refs/heads/${branch}" ]]; then
        printf '%s\n' "$current_path"
        return 0
      fi
    fi
  done < <(git -C "$REPO_ROOT" worktree list --porcelain)
  return 1
}

create_worktree() {
  local feature="$1"
  local desired_dir="$2"
  local branch="feature/${feature}"
  local existing_path

  git -C "$REPO_ROOT" fetch "$REMOTE" "$BASE_BRANCH"

  if worktree_dir_in_use "$desired_dir"; then
    printf '%s\n' "$desired_dir"
    return 0
  fi

  if existing_path="$(worktree_path_for_branch "$branch")"; then
    echo "Branch $branch already checked out at $existing_path; reusing." >&2
    printf '%s\n' "$existing_path"
    return 0
  fi

  if [[ -d "$desired_dir" ]]; then
    echo "Directory $desired_dir exists but is not registered as a worktree. Aborting." >&2
    exit 1
  fi

  if git -C "$REPO_ROOT" rev-parse --verify --quiet "$branch"; then
    git -C "$REPO_ROOT" worktree add "$desired_dir" "$branch"
  else
    git -C "$REPO_ROOT" worktree add "$desired_dir" -b "$branch" "$REMOTE/$BASE_BRANCH"
  fi

  printf '%s\n' "$desired_dir"
}

run_in_worktree() {
  local dir="$1"; shift
  (cd "$dir" && "$@")
}

run_flutter_checks() {
  local dir="$1"
  local feature="$2"
  run_in_worktree "$dir" bash -lc "set -euo pipefail; cd \"$APP_SUBDIR\"; echo \"Running Flutter checks for ${feature}\"; flutter pub get; flutter analyze; dart format --set-exit-if-changed .; flutter test"
}

commit_and_push() {
  local dir="$1"
  local msg="$2"
  local branch
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD)"

  git -C "$dir" add -A
  if git -C "$dir" diff --cached --quiet; then
    echo "No staged changes to commit in $dir." >&2
    return 0
  fi

  git -C "$dir" commit -m "$msg"
  if [[ "$PUSH_ENABLED" != "1" ]]; then
    echo "Skipping push for $branch (PUSH_ENABLED!=1)." >&2
    return 0
  fi
  git -C "$dir" push -u "$REMOTE" "$branch"
}

open_pr() {
  local dir="$1"
  local title="$2"
  local body="${3:-""}"
  gh -C "$dir" pr create --fill --title "$title" --body "$body" --base "$BASE_BRANCH"
}

cleanup_worktree() {
  local dir="$1"
  git -C "$REPO_ROOT" worktree remove "$dir"
  git -C "$REPO_ROOT" worktree prune || true
}

# Usage: pass feature names as arguments, or set FEATURES="feat-a feat-b"
# Example: ./worktree_run.sh "add-dice-anim" "fix-board-layout"
FEATURES="${FEATURES:-$*}"
if [[ -z "$FEATURES" ]]; then
  echo "Usage: FEATURES=\"feat-a feat-b\" $0  (or pass features as args)" >&2
  exit 1
fi

for feature in $FEATURES; do
  branch="feature/${feature}"
  dir="${REPO_ROOT}/../repo-wt-${feature}"
  dir="$(create_worktree "$feature" "$dir")"
  run_flutter_checks "$dir" "$feature"
  commit_and_push "$dir" "feat(${feature}): implementation & tests"
  # open_pr "$dir" "feat(${feature}): PR" "Automated PR creation"
  # cleanup_worktree "$dir"
done
