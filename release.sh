#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: bash release.sh <version>"
    echo "Example: bash release.sh 1.1.0"
    exit 1
fi

VERSION="v$1"

echo "Creating release $VERSION..."

git tag -a "$VERSION" -m "$VERSION"
git push origin "$VERSION"
gh release create "$VERSION" --title "$VERSION" --generate-notes

echo "Release $VERSION created!"
