# Get the default branch name (main/master) for the current repo
git_default_branch() {
    local ref
    ref="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)" || {
        echo "Could not determine default branch. Run: git remote set-head origin --auto" >&2
        return 1
    }
    echo "${ref#refs/remotes/origin/}"
}
