#!/bin/bash

if git show-ref --quiet --verify refs/heads/"$_BRANCH_NAME"; then
  echo "Branch '$_BRANCH_NAME' exists, nothing for me to do here."
  exit 0
else
  echo "Branch '$_BRANCH_NAME' does not exist, proceeding."
fi

# Create and switch to the new branch
git checkout -b "$_BRANCH_NAME"

echo "setting version to $_NEW_VERSION"

echo "updating version in version.yml..."
sed -i "s/ version: *.*/ version: $_NEW_VERSION/g" "./main/version.yml"

# Add all files to the staging area
git add .

# Commit the changes
git commit -m "bumping version to $_NEW_VERSION"

# Push the new branch to the remote repository
git push origin "$_BRANCH_NAME"
