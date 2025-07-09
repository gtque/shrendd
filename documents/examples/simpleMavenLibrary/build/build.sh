#!/bin/bash

_version="1.0.0"
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
zip "./target/${_version}/simpleLibrary.zip" version.yml
#zip contents of each main/[target] to target/[version]/[target].zip, include version.yml in the zip file
cd deploy
echo "processing targets"
for target in $_targets; do
  echo " zipping $target"
  zip -r "../target/${_version}/simpleLibrary.zip" "$target"
done
echo "building finished"
echo  "------------------------------------"
echo "time to upload"
cd ..
docker build --network=host --build-arg TARGET_VERSION=${_version} --target=publish $_EXTRA_ARGS -f ./build/Dockerfile-mvn . --progress=plain
