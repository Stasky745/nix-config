# Git remove branches (keep main/master/default)
git-rm-br() {
    # Get the default branch name from remote
    local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

    # Fallback if no default branch is set
    if [[ -z "$default_branch" ]]; then
        default_branch=$(git branch -r | grep -E 'origin/(main|master)' | head -1 | sed 's/.*origin\///')
    fi

    # Get current branch
    local current_branch=$(git branch --show-current)

    # Delete all branches except protected ones
    git branch --no-color | grep -v -E "(^\*|^  (main|master|''${default_branch}|''${current_branch})$)" | xargs -r git branch -d

    git branch
}
