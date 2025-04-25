#!/bin/bash

is_git_repo() {
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

check_uncommitted() {
  local repo_dir="$1"
  cd "$repo_dir" || return
  
  # check for uncommitted changes in tracked files
  if ! git diff-index --quiet HEAD --; then
    echo "$repo_dir (uncommitted changes)"
  fi
  
  # check for untracked files
  if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "$repo_dir (untracked files)"
  fi
  
  cd - >/dev/null || return
}

check_unpushed() {
  local repo_dir="$1"
  cd "$repo_dir" || return
  
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    # check if branch has an upstream configured
    if git rev-parse --verify -q "$branch"@{upstream} >/dev/null 2>&1; then
      # check for unpushed commits
      if [ -n "$(git log "$branch"@{upstream}.."$branch" --oneline)" ]; then
        echo "$repo_dir (unpushed changes on branch $branch)"
      fi
    else
      echo "$repo_dir (branch $branch has no upstream)"
    fi
  done
  
  cd - >/dev/null || return
}

check_directories() {
  local dir=$(realpath "$1")
  local depth="$2"
  
  if is_git_repo "$dir"; then
    check_uncommitted "$dir"
    check_unpushed "$dir"
  fi
  
  if [ "$depth" -gt 0 ]; then
    for subdir in "$dir"/*; do
      if [ -d "$subdir" ] && [ ! -L "$subdir" ]; then  # Skip symbolic links
        check_directories "$subdir" $((depth-1))
      fi
    done
  fi
}

# set default depth
DEPTH=${2:-2}

if [ -z "$1" ]; then
  echo "Usage: $0 <directory> [depth]"
  exit 1
fi

check_directories "$1" "$DEPTH"