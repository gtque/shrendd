#!/bin/bash
echo "initializing shrendd for tests"
if [ -d ./.shrendd ]; then
  rm -rf ./.shrendd
fi
rm -f ./shrendd
echo "copying latest shrendd"
cp ../../main/shrendd .
_VERSION=$(yq e ".shrendd.version" ../../main/version.yml)
sed -i "s/_UPSHRENDD_VERSION=\".*\"/_UPSHRENDD_VERSION=\"$_VERSION\"/g" "./shrendd"