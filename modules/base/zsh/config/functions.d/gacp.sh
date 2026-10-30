# Git add (all, or the given paths), commit and push
gacp() {
    if [ -z "$1" ]; then
        echo "Usage: gacp <message> [path...]" >&2
        return 1
    fi

    local message="$1"
    shift

    if [ $# -eq 0 ]; then
        git add -A || return 1
    else
        git add -- "$@" || return 1
    fi

    git commit -m "$message" && git push
}
