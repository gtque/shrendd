#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
mkdir ./.shrendd
cp -r ./test-init/crib ./.shrendd/crib
rm -rf ./deploy/target
if [ $# -gt 0 ]; then
  ./shrendd
  echo "debug test end!!!"
  exit 0
fi
_valid=$(./shrendd)
echo -e "$_valid"
echo "checking results"
export test_results="plugins_get:\n"
_house=$(echo -e "$_valid" | grep "house greeting: welcome to my abode." || echo "not found")
_shanty=$(echo -e "$_valid" | grep "shanty greeting: good luck" || echo "not found")
_crib=$(echo -e "$_valid" | grep "crib greeting: howdy" || echo "not found")
_mobile=$(echo -e "$_valid" | grep "mobile greeting: sup" || echo "not found")
if [[ "$_house" != "not found" ]]; then
  passed "plugin property in shrendd.yml"
else
  failed "plugin property in shrendd.yml"
fi
if [[ "$_shanty" != "not found" ]]; then
  passed "plugin property from plugin defaults"
else
  failed "plugin property from plugin defaults"
fi
if [[ "$_crib" != "not found" ]]; then
  passed "plugin not updated, already have matching version"
else
  failed "plugin not updated, local test-init was replaced for some reason"
fi
if [[ "$_mobile" != "not found" ]]; then
  passed "plugin properties file"
else
  failed "plugin properties file"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh