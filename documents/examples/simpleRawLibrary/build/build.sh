#!/bin/bash

_version="v1.0.0"
if [[ -d ./target ]]; then
  :
else
  mkdir ./target
fi
if [[ -d ./target/${_version} ]]; then
  :
else
  mkdir ./target/${_version}
fi
_targets="render k8s"

cp ./version.yml ./target/${_version}
zip "./target/${_version}/simpleRawLibrary.zip" version.yml
#zip contents of each main/[target] to target/[version]/[target].zip, include version.yml in the zip file
cd deploy
echo "processing targets"
for target in $_targets; do
  echo " zipping $target"
  zip -r "../target/${_version}/simpleRawLibrary.zip" "$target"
done
echo "building finished"
echo  "------------------------------------"
echo "time to upload"
cd ../target/${_version}
curl -v -u 'splinter:tmnt' --upload-file simpleRawLibrary.zip "http://localhost:8081/repository/shrendd-zip/simpleRawLibrary/${_version}/simpleRawLibrary.zip"
curl -v -u 'splinter:tmnt' --upload-file version.yml "http://localhost:8081/repository/shrendd-zip/simpleRawLibrary/${_version}/version.yml"