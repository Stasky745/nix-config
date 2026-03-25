# Git remove branches (keep main/master/default)
git-rm-br() {
    local default_branch
    default_branch="$(git_default_branch)" || return 1

    # Switch to default branch so current branch can be deleted
    git switch "$default_branch" || return 1

    # Delete all branches except protected ones (-d won't delete unmerged branches)
    local branches
    branches=$(git branch --no-color | grep -v -E "(^\*|^  (main|master|''${default_branch})$)")

    if [ -n "$branches" ]; then
        echo "$branches" | xargs git branch -d
    else
        echo "No branches to delete."
    fi

    git branch
}
