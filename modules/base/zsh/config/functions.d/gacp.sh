# Git add (all, or the given paths), commit and push
gacp() {
    if [ -z "$1" ]; then
        echo "Usage: gacp <message> [path...]" >&2
        return 1
    fi

    local message="$1"
    shift

    if git rev-parse --verify --quiet "@{upstream}" >/dev/null; then
        git fetch --quiet || return 1
        if [ "$(git rev-list --count "HEAD..@{upstream}")" -gt 0 ]; then
            git pull --autostash || return 1
        fi
    fi

    # git pull exits 0 even when re-applying the autostash conflicts
    if [ -n "$(git ls-files --unmerged)" ]; then
        echo "Conflicts after pulling; resolve them (your changes are also kept in git stash), then re-run gacp" >&2
        return 1
    fi

    if [ $# -eq 0 ]; then
        git add -A || return 1
    else
        git add -- "$@" || return 1
    fi

    git commit -m "$message" && git push
}
