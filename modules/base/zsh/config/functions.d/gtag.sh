gtag() {
  if [ -z "$1" ]; then
    echo "usage: gtag <tag>"
    return 1
  fi

  local tag="$1"

  gp &&
    git tag "$tag" &&
    git push origin tag "$tag"
}
