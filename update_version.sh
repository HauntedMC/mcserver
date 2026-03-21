#!/usr/bin/env bash
set -euo pipefail

current_version=$(cat version.txt)
version=${current_version#v}

IFS='.' read -r major minor patch <<< "$version"

increment_version() {
  case "$1" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      echo "Usage: $0 <major|minor|patch>" >&2
      exit 1
      ;;
  esac
}

increment_version "${1:-}"

new_version="v${major}.${minor}.${patch}"

echo "New version: $new_version"
echo "$new_version" > version.txt

git add version.txt
git commit -m "Bump version to $new_version for release"
git tag "$new_version"

echo "Version updated locally. Push the branch and tag when ready:"
echo "  git push && git push origin $new_version"
