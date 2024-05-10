#!/bin/bash

# Check if a directory is a Git repository
is_git_repo() {
    git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# Check for uncommitted changes
check_uncommitted() {
    local repo_dir="$1"
    cd "$repo_dir" || return

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "$repo_dir (uncommitted changes)"
    fi

    cd - >/dev/null || return
}

# Check for unpushed changes
check_unpushed() {
    local repo_dir="$1"

    cd "$repo_dir" || return

    # Check for unpushed changes across all branches
    for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
        if [ "$branch" != "$(git symbolic-ref --short HEAD)" ]; then
            if ! git rev-list "$branch"@{upstream}..HEAD --quiet; then
                echo "$repo_dir (unpushed changes on branch $branch)"
            fi
        fi
    done

    cd - >/dev/null || return
}

# Check directories recursively
check_directories() {
    local dir=$(realpath "$1")
    local depth="$2"

    # Check if the current directory is a Git repository
    if is_git_repo "$dir"; then
        check_uncommitted "$dir"
        check_unpushed "$dir"
    fi

    # Recursively check subdirectories
    if [ "$depth" -gt 0 ]; then
        for subdir in "$dir"/*; do
            if [ -d "$subdir" ]; then
                check_directories "$subdir" $((depth-1))
            fi
        done
    fi
}

# Usage
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

check_directories "$1" 2