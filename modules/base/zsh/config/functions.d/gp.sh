# Git pull main/master branch (fast-forward only)
gp() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not inside a Git repository" >&2
        return 1
    fi

    local default_branch
    default_branch="$(git_default_branch)" || return 1

    git switch "$default_branch" && git pull --ff-only
}
