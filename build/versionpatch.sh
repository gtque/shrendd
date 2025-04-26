#!/bin/bash
export _NEW_VERSION="not-set"

export _SHRENDD=$(cat ./main/version.yml)
#get version from version.yml
export _VERSION=$(echo -e "$_SHRENDD" | yq e ".shrendd.version" -)

if [ $# -gt 0 ]; then
  export _NEW_VERSION=$1
else
  echo "bumping patch version"
  _MAJOR=$(echo "$_VERSION" | cut -d'.' -f1)
  _MINOR=$(echo "$_VERSION" | cut -d'.' -f2)
  _PATCH=$(echo "$_VERSION" | cut -d'.' -f3)
  if [ -z "$_PATCH" ]; then
    echo "ya done messed up a-a-ron."
    export _NEW_VERSION="a-a-ron"
  else
    _PATCH=$(echo "$_PATCH" | cut -d'-' -f1)
    if [[ "$_PATCH" =~ ^[0-9]+$ ]]; then
      echo "patch: $_PATCH + 1"
      ((_PATCH++))
      echo "new patch: $_PATCH"
      export _NEW_VERSION="$_MAJOR.$MINOR.$_PATCH"
    else
      echo "something is not right, please manually verify, and update if necessary, the version.yml file."
      exit 42
    fi
  fi
fi
echo "bumping version from $_VERSION to $_NEW_VERSION"

echo "updating version in version.yml..."
sed -i "s/ version: *.*/ version: $_NEW_VERSION/g" "./main/version.yml"
