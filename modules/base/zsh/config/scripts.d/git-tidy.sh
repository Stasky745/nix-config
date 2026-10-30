# git tidy [-n dry run] [-y no prompt] [repo...]: delete local branches merged (plain/squash/rebase) into origin's default branch

usage() {
    echo "usage: git tidy [-n] [-y] [repo...]" >&2
    exit 2
}

tidy_repo() {
    local repo="$1"
    local name default target candidates tmp branch base bases oldest id ids reply

    name="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" || {
        echo "$repo: not a git repository" >&2
        return 1
    }
    name="${name##*/}"
    default="$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" || {
        echo "$name: could not determine default branch. Run: git remote set-head origin --auto" >&2
        return 1
    }
    default="${default#origin/}"
    git -C "$repo" fetch --prune --quiet origin || return 1
    target="origin/$default"

    # Branches checked out in any worktree have a worktreepath and are skipped
    candidates="$(git -C "$repo" for-each-ref --format='%(refname:short) %(worktreepath)' refs/heads |
        awk -v d="$default" '$2 == "" && $1 != d && $1 !~ /^(main|master|develop|staging|trunk)$/ { print $1 }')"
    [ -n "$candidates" ] || return 0

    tmp="$(mktemp -d)" || return 1
    : > "$tmp/delete"
    : > "$tmp/check"

    while read -r branch; do
        if git -C "$repo" merge-base --is-ancestor "$branch" "$target"; then
            echo "$branch merged $(git -C "$repo" rev-parse --short "$branch")" >> "$tmp/delete"
        elif base="$(git -C "$repo" merge-base "$target" "$branch")"; then
            echo "$branch $base" >> "$tmp/check"
        fi
    done <<< "$candidates"

    if [ -s "$tmp/check" ]; then
        bases="$(cut -d' ' -f2 "$tmp/check" | sort -u)"
        oldest="$(echo "$bases" | xargs git -C "$repo" merge-base --octopus)"
        git -C "$repo" log -p --no-merges --no-color --no-ext-diff "$target" "^$oldest" |
            git patch-id --stable | cut -d' ' -f1 | sort -u > "$tmp/target_ids"

        while read -r branch base; do
            id="$(git -C "$repo" diff --no-color --no-ext-diff "$base" "$branch" | git patch-id --stable | cut -d' ' -f1)"
            if [ -n "$id" ] && grep -qxF "$id" "$tmp/target_ids"; then
                echo "$branch squash-merged $(git -C "$repo" rev-parse --short "$branch")" >> "$tmp/delete"
                continue
            fi
            ids="$(git -C "$repo" log -p --no-merges --no-color --no-ext-diff "$base..$branch" | git patch-id --stable | cut -d' ' -f1)"
            if [ -n "$ids" ] && ! grep -vxF -f "$tmp/target_ids" <<< "$ids" | grep -q .; then
                echo "$branch rebase-merged $(git -C "$repo" rev-parse --short "$branch")" >> "$tmp/delete"
            fi
        done < "$tmp/check"
    fi

    if [ -s "$tmp/delete" ]; then
        echo "$name: $(wc -l < "$tmp/delete" | tr -d ' ') of $(echo "$candidates" | wc -l | tr -d ' ') branches merged into $target"
        awk '{ printf "  %-15s %s  %s\n", $2, $3, $1 }' "$tmp/delete"
        if ! $dry_run; then
            reply=n
            if $assume_yes; then
                reply=y
            else
                printf "Delete them? [y/N] "
                read -r reply || reply=n
            fi
            case "$reply" in
                [yY]*) cut -d' ' -f1 "$tmp/delete" | xargs git -C "$repo" branch -D --quiet ;;
            esac
        fi
    fi
    rm -rf "$tmp"
}

dry_run=false
assume_yes=false
while getopts "nyh" opt; do
    case "$opt" in
        n) dry_run=true ;;
        y) assume_yes=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
[ $# -eq 0 ] && set -- .

rc=0
for repo in "$@"; do
    tidy_repo "$repo" || rc=1
done
exit $rc
