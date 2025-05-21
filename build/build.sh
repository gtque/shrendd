#!/bin/bash
echo "I want to be a triangle - Ralph Wiggum"
echo "running tests..."
./build/test.sh
if [ $? -ne 0 ]; then
  echo "There were test failures, stopping build."
  exit 1
fi
export _SHRENDD=$(cat ./main/version.yml)
_targets="render k8s test"
export _BRANCH_NAME=$(git branch --show-current)
echo "the branch: $_BRANCH_NAME"
export _PRE_RELEASE=""
export _IS_PRE_RELEASE="true"
export _IS_LATEST="false"
export _PUBLISHING="false"

if [[ $(type -t check_for_release) == function ]]; then
  echo "check by checking releases"
  export _PUBLISHING="true"
else
  echo "check by checking local file exists"
fi

if [[ "$_BRANCH_NAME" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "on a release branch."
  export _IS_PRE_RELEASE="false"
  export _IS_LATEST="true"
else
  if [ "$_BRANCH_NAME" == "main" ]; then
    echo "on main"
    export _PRE_RELEASE="-beta"
  else
    echo "seems like you are on a feature branch."
    _VERSION_SAFE_BRANCH="${_BRANCH_NAME//[^[:alnum:] -._]/.}"
    _VERSION_SAFE_BRANCH="${_VERSION_SAFE_BRANCH//[ ]/.}"
    _VERSION_SAFE_BRANCH="${_VERSION_SAFE_BRANCH//[_]/-}"
    export _PRE_RELEASE="-alpha+$_VERSION_SAFE_BRANCH"
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

export _ALREADY_EXISTS="false"
if [ "$_PUBLISHING" == "true" ]; then
  check_for_release $_VERSION $_BRANCH_NAME
  echo "does release exist: $_RELEASE_EXISTS"
  export _ALREADY_EXISTS="$_RELEASE_EXISTS"
else
  if [ -d "build/target/$_VERSION" ]; then
    export _ALREADY_EXISTS="true"
  fi
fi
if [ "$_ALREADY_EXISTS" == "true" ]; then
  echo "target/$_VERSION exists"
  counter=1
  while true; do
    if [ "$_PUBLISHING" == "true" ]; then
      check_for_release "$_VERSION.$counter" $_BRANCH_NAME
      echo "does release exist: $_RELEASE_EXISTS"
      export _ALREADY_EXISTS="$_RELEASE_EXISTS"
    else
      directory="build/target/${_VERSION}.$counter"
      if [ ! -d "$directory" ]; then
        #break  # Exit the loop if the directory doesn't exist
        export _ALREADY_EXISTS="false"
        echo "directory already exists... while try another"
      else
        echo "not a directory: $directory"
        export _ALREADY_EXISTS="true"
      fi
      echo "Directory $directory exists $_ALREADY_EXISTS"
    fi
    if [ "$_ALREADY_EXISTS" == "false" ]; then
      break
    fi
    ((counter++))
  done
  export _VERSION=$(echo "${_VERSION}.$counter")
  #mv "build/target/$_VERSION" "build/target/${_VERSION}.$counter"
else
  echo "what target?"
fi

if [ "$_PUBLISHING" == "true" ]; then
  if [ -d "build/target/$_VERSION" ]; then
    rm -rf "build/target/$_VERSION"
  fi
fi

echo "building: $_VERSION"
#copy shrendd and version.yml to target/[version] directory
mkdir "build/target/$_VERSION"
echo "copy shrendd"
cp main/shrendd "build/target/$_VERSION/"
echo "updating version in shrendd file..."
sed -i "s/_UPSHRENDD_VERSION=\".*\"/_UPSHRENDD_VERSION=\"$_VERSION\"/g" "./build/target/$_VERSION/shrendd"

echo "copy version"
cp main/version.yml "build/target/$_VERSION/"
sed -i "s/ version: *.*/ version: $_VERSION/g" "./build/target/$_VERSION/version.yml"

#zip contents of each main/[target] to target/[version]/[target].zip, include version.yml in the zip file
cd main
echo "add core shrendd files to render.zip"
zip "../build/target/$_VERSION/render.zip" upshrendd
zip "../build/target/$_VERSION/render.zip" deploy.sh
zip "../build/target/$_VERSION/render.zip" stub.sh
zip "../build/target/$_VERSION/render.zip" parse_parameters.sh
cd ../build/target/$_VERSION
zip "./render.zip" version.yml
cd ../../../main
echo "processing targets"
for target in $_targets; do
  echo " zipping $target"
  zip -r "../build/target/$_VERSION/$target.zip" "$target"
done
echo "building finished"
echo  "------------------------------------"
cd ..