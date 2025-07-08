#!/bin/bash

_version="1.0.0-SNAPSHOT"
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
docker build --build-arg TARGET_VERSION=1.0.0-SNAPSHOT --target=publish $_EXTRA_ARGS -f ./build/Dockerfile-mvn . --progress=plain
#cd ../target/${_version}
#mvn -X -f pom.xml deploy:deploy-file -Dtest.publish=true -Dfile=target/${_version}/simpleLibrary.zip -DpomFile=pom.xml -Durl=http://localhost:8081/repository/maven-snapshots -Dpackaging=zip
#mvn -X -f pom.xml deploy:deploy-file -Dtest.publish=true -Dfile=target/${_version}/version.yml -DpomFile=pom.xml -Durl=http://localhost:8081/repository/maven-snapshots -Dpackaging=yml

#curl -v -u 'splinter:tmnt' --upload-file simpleLibrary.zip "http://localhost:8081/repository/shrendd-zip/${_version}/simpleLibrary.zip"
#curl -v -u 'splinter:tmnt' --upload-file version.yml "http://localhost:8081/repository/shrendd-zip/${_version}/version.yml"