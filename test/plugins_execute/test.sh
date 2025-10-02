#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
mkdir ./.shrendd
rm -rf ./deploy/target
rm -rf ./deploy/cheese
cp -r ./test-init/cheese ./.shrendd/cheese
if [ $# -gt 0 ]; then
  ./shrendd -r -verbose
  exit 0
fi
_shrendd=$(./shrendd -r)
#./shrendd -d
echo -e "$_shrendd"
_shrendd2=$(./shrendd -r --config localdev-alt.yml)
echo -e "$_shrendd2"
export test_results="plugin_execute, & some additional skip template testing:\n"
_shrendded=$(echo -e "$_shrendd" | grep "skipping 42_configmap_skip.yml.srd due to condition not met:" || echo "not found")
_not_shrendded=$(echo -e "$_shrendd2" | grep "skipping 42_configmap_skip.yml.srd due to condition not met:" || echo "not found")
if [ "$_shrendded" == "not found" ]; then
  passed "executePlugin - true"
else
  failed "executePlugin - true"
fi
if [ "$_not_shrendded" != "not found" ]; then
  passed "executePlugin - false"
else
  failed "executePlugin - false"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
