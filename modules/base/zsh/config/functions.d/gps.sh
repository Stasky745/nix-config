# Update the default branch, then switch to (or create) a branch with it merged in; uncommitted changes carry over
gps() {
    if [ -z "$1" ]; then
        echo "Usage: gps <branch-name>" >&2
        return 1
    fi

    local branch_name="$1"
    local default_branch current_branch

    default_branch="$(git_default_branch)" || return 1
    current_branch="$(git branch --show-current)"

    # Fast-forward the local default branch without switching to it
    if [ "$current_branch" = "$default_branch" ]; then
        git pull --ff-only || return 1
    else
        git fetch origin "$default_branch:$default_branch" || return 1
    fi

    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        if [ "$current_branch" != "$branch_name" ]; then
            git switch "$branch_name" || return 1
        fi
        git merge --autostash "$default_branch"
    else
        git switch -c "$branch_name" "$default_branch"
    fi
}
