#!/bin/bash
set -euo pipefail

echo "I want to be a triangle - Ralph Wiggum"
export _SHRENDD=$(cat ./main/version.yml)
_targets="render k8s test"
#get version from version.yml
export _VERSION=$(echo -e "$_SHRENDD" | yq e ".shrendd.version" -)
export _VERSION=$(eval "echo -e \"$_VERSION\"")
echo "version: $_VERSION"

echo "updating version in shrendd file..."
sed -i "s/_UPSHRENDD_VERSION=\".*\"/_UPSHRENDD_VERSION=\"$_VERSION\"/g" "./main/shrendd"

if [ -d "build/target" ]; then
  echo "target exists"
else
  mkdir build/target
fi

if [ -d "build/target/$_VERSION" ]; then
  echo "target/$_VERSION exists"
  counter=1
  while true; do
    directory="build/target/${_VERSION}_$counter"
    if [ ! -d "$directory" ]; then
      break  # Exit the loop if the directory doesn't exist
    fi
    echo "Directory $directory exists"
    ((counter++))
  done
  mv "build/target/$_VERSION" "build/target/${_VERSION}_$counter"
else
  echo "what target?"
fi
#copy shrendd and version.yml to target/[version] directory
mkdir "build/target/$_VERSION"
echo "copy shrendd"
cp main/shrendd "build/target/$_VERSION/"
echo "copy verison"
cp main/version.yml "build/target/$_VERSION/"
#zip contents of each main/[target] to target/[version]/[target].zip, include version.yml in the zip file
cd main
echo "add core shrendd files to render.zip"
zip "../build/target/$_VERSION/render.zip" upshrendd
zip "../build/target/$_VERSION/render.zip" version.yml
zip "../build/target/$_VERSION/render.zip" deploy.sh
zip "../build/target/$_VERSION/render.zip" stub.sh
zip "../build/target/$_VERSION/render.zip" parse_parameters.sh
echo "processing targets"
for target in $_targets; do
  echo " zipping $target"
  zip -r "../build/target/$_VERSION/$target.zip" "$target"
done
