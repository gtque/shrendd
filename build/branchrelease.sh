#!/bin/bash
set -euo pipefail
export _NEW_VERSION="not-set"
export _SHRENDD=$(cat ./main/version.yml)

#get version from version.yml
export _VERSION=$(echo -e "$_SHRENDD" | yq e ".shrendd.version" -)
export _BRANCH_NAME=$(git branch --show-current)
if [ "$_BRANCH_NAME" == "main" ]; then
  echo "in main branch"
else
  echo "not in main branch, please release branching should only be done from the main branch, please switch branches and try again."
  exit 2
fi
#_beta="-beta"
#if [[ $_VERSION == *$_beta ]]; then
#  echo "is beta branch, can branch for release."
#else
#  echo "is not beta branch, please switch to main and make sure main is updated before trying to branch for release again."
#  exit 42
#fi
_MAJOR=$(echo "$_VERSION" | cut -d'.' -f1)
_SPLICED=$(echo "$_VERSION" | cut -d'.' -f2)
if [ -z "$_SPLICED" ]; then
  echo "ya done messed up a-a-ron."
  export _NEW_VERSION="a-a-ron"
else
  _SPLICED=$(echo "$_SPLICED" | cut -d'-' -f1)
  if [[ "$_SPLICED" =~ ^[0-9]+$ ]]; then
    #((_SPLICED++))
    export _NEW_VERSION="$_MAJOR.$_SPLICED.0"
    export _BRANCH_NAME="$_MAJOR.$_SPLICED"
  else
    echo "something is not right, please manually verify, and update if necessary, the version.yml file."
    exit 42
  fi
fi

./build/branchdo.sh
git checkout main
./build/version.sh

# Commit the changes
git commit -m "bumping version to $_NEW_VERSION"

# Push the new branch to the remote repository
git push