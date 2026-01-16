# Git pull and switch to branch (with stash support)
gps() {
    if [ -z "$1" ]; then
    echo "Usage: gps <branch-name>"
    return 1
    fi

    local branch_name="$1"
    local stashed=false

    # Stash changes only if there are changes to stash
    if ! git diff-index --quiet HEAD --; then
    git stash
    stashed=true
    fi

    # Run gp (switch to the main branch and pull updates)
    gp

    # Check if the branch exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    git switch "$branch_name"
    git merge "$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@refs/remotes/origin/@@')"
    else
    git switch -c "$branch_name"
    fi

    # Unstash changes only if we stashed something
    if [ "$stashed" = true ]; then
    git stash pop
    fi
}
