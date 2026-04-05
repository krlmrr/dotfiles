#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: bash release.sh <version>"
    echo "Example: bash release.sh 1.1.0"
    exit 1
fi

VERSION="$1"

echo "Creating release $VERSION..."

git tag -a "$VERSION" -m "$VERSION"
git push origin "$VERSION"

echo "Tag $VERSION pushed! GitHub Action will create the release."
