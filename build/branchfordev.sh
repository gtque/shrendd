#!/bin/bash
set -euo pipefail
if [ $# -gt 0 ]; then
  export _BRANCH_NAME=$1
else
  echo "you must specify the branch name"
  exit 1
fi

export _NEW_VERSION="not-set"

export _SHRENDD=$(cat ./main/version.yml)
#get version from version.yml
export _VERSION=$(echo -e "$_SHRENDD" | yq e ".shrendd.version" -)

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
  else
    echo "something is not right, please manually verify, and update if necessary, the version.yml file."
    exit 42
  fi
fi

./build/branchdo.sh