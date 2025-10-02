#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
if [ $# -gt 0 ]; then
  ./shrendd -r -verbose
  exit 0
fi
_shrendd=$(./shrendd -r)
#./shrendd -d
echo -e "$_shrendd"
_shrendd2=$(./shrendd -r --config localdev-alt.yml)
echo -e "$_shrendd2"
export test_results="k8s_skip, configmap only:\n"
_shrendded=$(echo -e "$_shrendd" | grep "skipping 42_configmap_skip.yml.srd due to condition not met:" || echo "not found")
_not_shrendded=$(echo -e "$_shrendd2" | grep "skipping 42_configmap_skip.yml.srd due to condition not met:" || echo "not found")
if [ "$_shrendded" == "not found" ]; then
  passed "shrenddIfTrue - true"
else
  failed "shrenddIfTrue - true"
fi
if [ "$_not_shrendded" != "not found" ]; then
  passed "shrenddIfTrue - false"
else
  failed "shrenddIfTrue - false"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
