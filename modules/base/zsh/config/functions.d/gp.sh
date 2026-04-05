# Git pull main/master branch
gp() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not inside a Git repository"
        return 1
    fi

    git switch "$(git_default_branch)" && git pull
}
