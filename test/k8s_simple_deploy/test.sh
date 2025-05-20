#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
_shrendd=$(./shrendd -d)
echo -e "$_shrendd"
export test_results="k8s simple deploy, configmap only:\n"

_configmap=$(kubectl -n shrendd-test get cm shrendd-test-single-level-localdev -o yaml)
_catniss=$(echo -e "$_configmap" | yq e ".data.test2" - | yq e ".pets.cats.[2].name" -)
_pie=$(echo -e "$_configmap" | yq e ".data.test6" - | yq e ".pies" - | yq e ".[1].name" -)
echo "************************************"
echo "tear down tests"
./shrendd -t
_teardown=$(kubectl -n shrendd-test get cm shrendd-test-single-level-localdev -o yaml || echo "not found")
echo "teardown finished"
echo "cat: $_catniss"
echo "pie: $_pie"
echo "teardown: $_teardown"
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
if [ "$_teardown" == "not found" ]; then
  export test_results="$test_results\ttear down: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}tear down: failed${_CLEAR_TEXT_COLOR}\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
