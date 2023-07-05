#!/bin/bash

# Read the current version from version.txt
current_version=$(cat version.txt)

# Remove the 'v' prefix from the version
version=${current_version#v}

# Parse the major, minor, and patch numbers
IFS='.' read -ra version_parts <<< "$version"
major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}

# Define the increment function
increment_version() {
    if [[ $1 == "major" ]]; then
        major=$((major + 1))
        minor=0
        patch=0
    elif [[ $1 == "minor" ]]; then
        minor=$((minor + 1))
        patch=0
    elif [[ $1 == "patch" ]]; then
        patch=$((patch + 1))
    else
        echo "Invalid input. Please specify 'major', 'minor', or 'patch'."
        exit 1
    fi
}

# Increment the version based on the input
increment_version "$1"

# Create the new version string
new_version="v${major}.${minor}.${patch}"

# Print the new version
echo "New version: $new_version"

# Overwrite the version file with the new version
echo "$new_version" > version.txt

git add version.txt
git commit -m "Bump version to $new_version for release"
git tag $new_version
git push
git push origin $new_version
