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

#single zip file with plugin and templates?
#that is possible, but then there will be dup files in the cache and .shrendd dirs.

#sh "rm -rf ./target"
#sh "mkdir ./target"
#def config = readYaml file: 'version.yml'
#config.version =env._VERSION
#writeYaml file: 'version.yml', data: config, overwrite: true
#sh "cp -r k8s-tenant-lifecycle-plugin/ ./target/k8s-tenant-lifecycle-plugin/"
#sh "cp -r templates/deploy/ ./target/templates/"
#sh "cp version.yml ./target/k8s-tenant-lifecycle-plugin/version.yml"
#sh "cp version.yml ./target/version.yml"
#dir('./target') {
#    sh "zip -r ${_ARTIFACT_ID}-plugin-${env._VERSION}.zip k8s-tenant-lifecycle-plugin/"
#    sh "zip -r ${_ARTIFACT_ID}-templates-${env._VERSION}.zip templates/"
#    sh "zip ${_ARTIFACT_ID}-templates-${env._VERSION}.zip version.yml"
#}