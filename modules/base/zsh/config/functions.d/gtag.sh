# Tag the updated default branch (annotated) and push it; without a tag, proposes svu's next version
gtag() {
    local tag="$1"
    local latest prefix reply

    gp || return 1

    if [ -z "$tag" ]; then
        latest="$(git describe --tags --abbrev=0 2>/dev/null)" || {
            echo "No tags yet. Usage: gtag <tag>" >&2
            return 1
        }
        # Keep the latest tag's prefix (v, nginx-v, none, ...)
        prefix="$(sed -E 's/[0-9]+\.[0-9]+\.[0-9]+$//' <<< "$latest")"
        tag="$(svu next --tag.prefix "$prefix" --tag.pattern "${prefix}[0-9]*")" || return 1

        if [ "$tag" = "$latest" ]; then
            echo "No feat/fix commits since $latest. Usage: gtag <tag>" >&2
            return 1
        fi

        printf "Tag %s (latest: %s)? [y/N] " "$tag" "$latest"
        read -r reply
        case "$reply" in
            [yY]*) ;;
            *) return 1 ;;
        esac
    fi

    git tag -a "$tag" -m "$tag" &&
        git push origin tag "$tag"
}
