#! /bin/bash
# token: github api user token retrieved from environment variable: GIT_API_TOKEN
# this token expires and new one needs to be created periodically.
# If publishing is failing, try generating a new token first.
# it needs to have the necessary permissions for creating a release.

# https://gist.github.com/schell/2fe896953b6728cc3c5d8d5f9f3a17a3
# requires curl and jq on PATH: https://stedolan.github.io/jq/
#https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#create-a-release
# create a new release
# user: user's github name, retrieved from version.yml: shrendd.git.user
# repo: the repo's github name, retrieved from version.yml: shrendd.git.repo
# requires: list of required pre-installed applications, retrieved from version.yml: shrendd.required
# token: github api user token retrieved from environment variable: GIT_API_TOKEN
# name: (1) version being published/released
# _branch: (2) the branch name being published from
# prerelease: (3) whether or not this is a release or a prerelease
# make_latest: (4) whether or not to make this the latest release
# body: (5) new functionality list, passed in when running the publish.sh script.
function create_release {
  export _SHRENDD=$(cat ./main/version.yml)
  user=$(echo -e "$_SHRENDD" | yq e ".shrendd.git.user" -)
  repo=$(echo -e "$_SHRENDD" | yq e ".shrendd.git.repo" -)
  requires=$(echo -e "$_SHRENDD" | yq e ".shrendd.required" -)
  echo "$_SHRENDD"
  echo "user: $user"
  echo "repo: $repo"
  echo "requires: $requires"
  #exit 0
  token=$GIT_API_TOKEN
  name=$1
  tag="v$name"
  _branch=$2
  prerelease=$3
  make_latest=$4
  body="## new functionality:\n$5\n\n### required applications:\n$requires"
  command="curl -s -o ./build/target/$_VERSION/release.json -w '%{http_code}' \
       --request POST \
       --header 'authorization: Bearer ${token}' \
       --header 'content-type: application/json' \
       --data '{\"tag_name\": \"${tag}\", \"tag_commitish\": \"${_branch}\", \"body\": \"${body}\", \"name\": \"${name}\", \"prerelease\": ${prerelease}, \"make_latest\": \"${make_latest}\"}' \
       https://api.github.com/repos/$user/$repo/releases"
  http_code=`eval $command`
  if [ $http_code == "201" ]; then
    echo "created release:"
    cat ./build/target/$_VERSION/release.json
  else
    echo "create release failed with code '$http_code':"
    cat ./build/target/$_VERSION/release.json
    echo "command:"
    echo "$command" | sed "s/$GIT_API_TOKEN/****/"
    return 1
  fi
}

# upload a release file.
# this must be called only after a successful create_release, as create_release saves
# the json response in release.json.
# token: github api user token
# file: path to the asset file to upload
# name: name to use for the uploaded asset
function upload_release_file {
  token=$GIT_API_TOKEN
  file=$1
  name=$2

  url=`jq -r .upload_url ./build/target/$_VERSION/release.json | cut -d{ -f'1'`
  command="\
    curl -s -o ./build/target/$_VERSION/upload.json -w '%{http_code}' \
         --request POST \
         --header 'authorization: Bearer ${token}' \
         --header 'Content-Type: application/octet-stream' \
         --data-binary @\"${file}\"
         ${url}?name=${name}"
  http_code=`eval $command`
  if [ $http_code == "201" ]; then
    echo "asset $name uploaded:"
    jq -r .browser_download_url ./build/target/$_VERSION/upload.json
  else
    echo "upload failed with code '$http_code':"
    cat ./build/target/$_VERSION/upload.json
    echo "command:"
    echo "$command" | sed "s/$GIT_API_TOKEN/****/"
    return 1
  fi
}

function check_for_release {
  export _SHRENDD=$(cat ./main/version.yml)
  user=$(echo -e "$_SHRENDD" | yq e ".shrendd.git.user" -)
  repo=$(echo -e "$_SHRENDD" | yq e ".shrendd.git.repo" -)
  requires=$(echo -e "$_SHRENDD" | yq e ".shrendd.required" -)
  echo "$_SHRENDD"
  echo "user: $user"
  echo "repo: $repo"
  echo "requires: $requires"
  #exit 0
  token=$GIT_API_TOKEN
  name=$1
  tag="v$name"
  echo "checking for release $_VERSION now..."
  command="curl -s -o ./build/target/$_VERSION/checkrelease.json -w '%{http_code}' \
         -H 'Accept: application/vnd.github+json' \
         -H 'Authorization: Bearer $GIT_API_TOKEN' \
         -H 'X-GitHub-Api-Version: 2022-11-28' \
         https://api.github.com/repos/$user/$repo/releases/tags/$tag"
  echo "about to execute..."
  echo "command:"
  echo "$command" | sed "s/$GIT_API_TOKEN/****/"
  http_code=`eval $command`
  echo "executed..."
  if [ $http_code == "200" ]; then
    echo "checked release:"
    export _RELEASE_EXISTS="true"
  else
    echo "check release failed with code '$http_code':"
    export _RELEASE_EXISTS="false"
  fi
}

function latest_release {
  export _SHRENDD=$(cat ./main/version.yml || cat ../../main/version.yml)
  user=$(echo -e "$_SHRENDD" | yq e ".shrendd.git.user" -)
  repo=$(echo -e "$_SHRENDD" | yq e ".shrendd.git.repo" -)
  requires=$(echo -e "$_SHRENDD" | yq e ".shrendd.required" -)
  echo "$_SHRENDD"
  echo "user: $user"
  echo "repo: $repo"
  echo "requires: $requires"
  #exit 0
  token=$GIT_API_TOKEN
  if [ $# -gt 0 ]; then
    _latest_release="$1"
  else
    _latest_release="./build/target/$_VERSION/latestrelease.json"
  fi
  #echo "checking for release $_VERSION now..."
  command="curl -s -o $_latest_release -w '%{http_code}' \
         -H 'Accept: application/vnd.github+json' \
         -H 'Authorization: Bearer $GIT_API_TOKEN' \
         -H 'X-GitHub-Api-Version: 2022-11-28' \
         https://api.github.com/repos/$user/$repo/releases/latest"
  echo "about to execute..."
  echo "command:"
  echo "$command" | sed "s/$GIT_API_TOKEN/****/"
  http_code=`eval $command`
  echo "executed..."
  if [ $http_code == "200" ]; then
    echo "latest release:"
    export _RELEASE=$(jq -r .name $_latest_release)
    echo "latest release: $_RELEASE"
  else
    echo "check release failed with code '$http_code':"
    export _RELEASE="false"
  fi
}