# Git pull main/master branch
gp() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git switch $(git symbolic-ref refs/remotes/origin/HEAD | sed 's@refs/remotes/origin/@@')
    git pull
    else
    echo "Not inside a Git repository"
    fi
}
