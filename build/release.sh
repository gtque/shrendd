#! /bin/bash
# https://gist.github.com/schell/2fe896953b6728cc3c5d8d5f9f3a17a3
# requires curl and jq on PATH: https://stedolan.github.io/jq/
#https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#create-a-release
# create a new release
# user: user's name
# repo: the repo's name
# token: github api user token
# tag: name of the tag pushed
create_release() {
    user=$1
    repo=$2
    token=$3
    tag=$4

    command="curl -s -o release.json -w '%{http_code}' \
         --request POST \
         --header 'authorization: Bearer ${token}' \
         --header 'content-type: application/json' \
         --data '{\"tag_name\": \"${tag}\"}' \
         https://api.github.com/repos/$user/$repo/releases"
    http_code=`eval $command`
    if [ $http_code == "201" ]; then
        echo "created release:"
        cat release.json
    else
        echo "create release failed with code '$http_code':"
        cat release.json
        echo "command:"
        echo $command
        return 1
    fi
}

# upload a release file.
# this must be called only after a successful create_release, as create_release saves
# the json response in release.json.
# token: github api user token
# file: path to the asset file to upload
# name: name to use for the uploaded asset
upload_release_file() {
    token=$1
    file=$2
    name=$3

    url=`jq -r .upload_url release.json | cut -d{ -f'1'`
    command="\
      curl -s -o upload.json -w '%{http_code}' \
           --request POST \
           --header 'authorization: Bearer ${token}' \
           --header 'Content-Type: application/octet-stream' \
           --data-binary @\"${file}\"
           ${url}?name=${name}"
    http_code=`eval $command`
    if [ $http_code == "201" ]; then
        echo "asset $name uploaded:"
        jq -r .browser_download_url upload.json
    else
        echo "upload failed with code '$http_code':"
        cat upload.json
        echo "command:"
        echo $command
        return 1
    fi
}