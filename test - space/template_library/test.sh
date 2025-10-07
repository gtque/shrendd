#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
./shrendd -r
echo "!!!!!!!!!!!!!!!!! evaluating !!!!!!!!!!!!!!!!"
export test_results="template_library:\n"
_configmap=$(cat ./deploy/target/render/k8s/09_configmap.yml)
_catniss=$(echo -e "$_configmap" | yq e ".data.test2" - | yq e ".pets.cats.[2].name" -)
_pie=$(echo -e "$_configmap" | yq e ".data.test6" - | yq e ".pies" - | yq e ".[1].name" -)
_four=$(cat ./deploy/target/render/render/test-text.txt | grep "four" || echo "not found")
_six=$(cat ./deploy/target/render/render/test-text.txt | grep "six" || echo "not found")
_false=$(cat ./deploy/target/render/render/test-text.txt | grep "false" || echo "not found")
echo "************************************"
echo "cat: $_catniss"
echo "pie: $_pie"
if [ "$_catniss" == "catniss" ]; then
  export test_results="$test_results\tk8s_to_yaml: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}k8s_to_yaml: failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_pie" == "pecan" ]; then
  export test_results="$test_results\tnested with array: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}nested with array: failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_four" == "    four" ]; then
  passed "indented text render (four)"
else
  failed "indented text render (four)"
fi
if [ "$_six" == "      six" ]; then
  passed "indented text render (six)"
else
  failed "indented text render (six)"
fi
if [ "$_false" == "not found" ]; then
  passed "shrenddIfTrue excluded from render"
else
  failed "shrenddIfTrue excluded from render"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
