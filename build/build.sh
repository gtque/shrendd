#!/bin/bash
set -euo pipefail

echo "I want to be a triangle - Ralph Wiggum"
export _SHRENDD=$(cat ./main/version.yml)
_targets="render k8s test"
export _BRANCH_NAME=$(git branch --show-current)
echo "the branch: $_BRANCH_NAME"
export _PRE_RELEASE=""
if [[ "$_BRANCH_NAME" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "on a release branch."
else
  if [ "$_BRANCH_NAME" == "main" ]; then
    echo "on main"
    export _PRE_RELEASE="-beta"
  else
    echo "seems like you are on a feature branch."
    export _PRE_RELEASE="-alpha"
  fi
fi
#get version from version.yml
export _VERSION=$(echo -e "$_SHRENDD" | yq e ".shrendd.version" -)
export _VERSION=$(eval "echo -e \"$_VERSION\"")
export _VERSION=$(echo "$_VERSION$_PRE_RELEASE")
echo "version: $_VERSION"

if [ -d "build/target" ]; then
  echo "target exists"
else
  mkdir build/target
fi

if [ -d "build/target/$_VERSION" ]; then
  echo "target/$_VERSION exists"
  counter=1
  while true; do
    directory="build/target/${_VERSION}.$counter"
    if [ ! -d "$directory" ]; then
      break  # Exit the loop if the directory doesn't exist
    fi
    echo "Directory $directory exists"
    ((counter++))
  done
  export _VERSION=$(echo "${_VERSION}.$counter")
  #mv "build/target/$_VERSION" "build/target/${_VERSION}.$counter"
else
  echo "what target?"
fi
if [ -d "build/target/version" ]; then
  echo "version exists, deleting it"
  rm -rf build/target/version
fi

mkdir build/target/version
cp main/version.yml "build/target/version/"
sed -i "s/ version: *.*/ version: $_VERSION/g" "./build/target/version/version.yml"

echo "updating version in shrendd file..."
sed -i "s/_UPSHRENDD_VERSION=\".*\"/_UPSHRENDD_VERSION=\"$_VERSION\"/g" "./main/shrendd"

#copy shrendd and version.yml to target/[version] directory
mkdir "build/target/$_VERSION"
echo "copy shrendd"
cp main/shrendd "build/target/$_VERSION/"
echo "copy version"
cp build/target/version/version.yml "build/target/$_VERSION/"
#zip contents of each main/[target] to target/[version]/[target].zip, include version.yml in the zip file
cd main
echo "add core shrendd files to render.zip"
zip "../build/target/$_VERSION/render.zip" upshrendd
zip "../build/target/$_VERSION/render.zip" deploy.sh
zip "../build/target/$_VERSION/render.zip" stub.sh
zip "../build/target/$_VERSION/render.zip" parse_parameters.sh
cd ../build/target/version
zip "../$_VERSION/render.zip" version.yml
cd ../../../main
echo "processing targets"
for target in $_targets; do
  echo " zipping $target"
  zip -r "../build/target/$_VERSION/$target.zip" "$target"
done
