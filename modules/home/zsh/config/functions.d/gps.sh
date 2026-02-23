# Git pull and switch to branch (with stash support)
gps() {
    if [ -z "$1" ]; then
        echo "Usage: gps <branch-name>"
        return 1
    fi

    local branch_name="$1"
    local default_branch
    local stashed=false

    default_branch="$(git_default_branch)" || return 1

    # Stash changes only if there are changes to stash
    if ! git diff-index --quiet HEAD --; then
        git stash
        stashed=true
    fi

    # Switch to default branch and pull updates
    gp || { _gps_abort_stash "$stashed"; return 1; }

    # Switch to the target branch (create if it doesn't exist)
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        git switch "$branch_name" || { _gps_abort_stash "$stashed"; return 1; }

        # Merge default branch into the feature branch
        if ! git merge "$default_branch"; then
            echo ""
            echo "Merge conflict with '$default_branch'."
            echo "Resolve the conflicts, then run: git stash pop"
            [ "$stashed" = true ] && echo "(You have stashed changes waiting.)"
            return 1
        fi
    else
        git switch -c "$branch_name" || { _gps_abort_stash "$stashed"; return 1; }
    fi

    # Unstash changes only if we stashed something
    if [ "$stashed" = true ]; then
        git stash pop
    fi
}

_gps_abort_stash() {
    if [ "$1" = true ]; then
        echo "Something went wrong. Restoring stashed changes."
        git stash pop
    fi
}
