#!/bin/bash
export _NEW_VERSION="not-set"

export _SHRENDD=$(cat ./main/version.yml)
#get version from version.yml
export _VERSION=$(echo -e "$_SHRENDD" | yq e ".shrendd.version" -)
echo "bumping major..."
if [ $# -gt 0 ]; then
  export _NEW_VERSION=$1
else
  _MAJOR=$(echo "$_VERSION" | cut -d'.' -f1)
  _MINOR=0
  _PATCH=0
  if [ -z "$_MAJOR" ]; then
    echo "ya done messed up a-a-ron."
    export _NEW_VERSION="a-a-ron"
  else
    echo "found major: $_MAJOR"
    _MAJOR=$(echo "$_MAJOR" | cut -d'-' -f1)
    if [[ "$_MAJOR" =~ ^[0-9]+$ ]]; then
      echo "bumping major $_MAJOR + 1"
      ((_MAJOR++))
      echo "new major: $_MAJOR"
      export _NEW_VERSION="$_MAJOR.$_MINOR.$_PATCH"
    else
      echo "something is not right, please manually verify, and update if necessary, the version.yml file."
      exit 42
    fi
  fi
fi
echo "bumping version from $_VERSION to $_NEW_VERSION"

echo "updating version in version.yml..."
sed -i "s/ version: *.*/ version: $_NEW_VERSION/g" "./main/version.yml"
