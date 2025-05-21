#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
_shrendd=$(./shrendd -d)
#./shrendd -d
echo -e "$_shrendd"
export test_results="k8s simple deploy, configmap only:\n"

_configmap=$(kubectl -n shrendd-test get cm shrendd-test-single-level-localdev -o yaml)
_catniss=$(echo -e "$_configmap" | yq e ".data.test2" - | yq e ".pets.cats.[2].name" -)
_configmap2=$(kubectl -n shrendd-test get cm shrendd-test-single-level-localdev-test -o yaml)
_testscript=$(echo -e "$_configmap2" | yq e ".data.[\"doSomething.sh\"]" -)
_pie=$(echo -e "$_configmap" | yq e ".data.test6" - | yq e ".pies" - | yq e ".[1].name" -)
echo "************************************"
echo "tear down tests"
_shrendd_t=$(./shrendd -t)
echo -e "$_shrendd_t"
_teardown=$(kubectl -n shrendd-test get cm shrendd-test-single-level-localdev -o yaml || echo "not found")
_pre_teardown=$(echo -e "$_shrendd_t" | grep "I run before anything of the rest of the teardown scripts, even before the standard teardown" || echo "not found")
echo "first pre check: $_pre_teardown"
_pre_teardown=$(echo -e "$_pre_teardown" | grep -v "echo" || echo "not found")
echo "second pre check: $_pre_teardown"
_post_teardown=$(echo -e "$_shrendd_t" | grep "I run after the standard teardown." || echo "not found")
echo "first post check: $_post_teardown"
_post_teardown=$(echo -e "$_post_teardown" | grep -v "echo" || echo "not found")
echo "second post check: $_post_teardown"
echo "teardown finished"
echo "cat: $_catniss"
echo "pie: $_pie"
echo "teardown: $_teardown"
echo "$_testscript"
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
if [[ "$_testscript" == *"I'm a brick"* ]]; then
  export test_results="$test_results\tk8s script render: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}k8s script render: failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_teardown" == "not found" ]; then
  export test_results="$test_results\ttear down: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}tear down: failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_pre_teardown" != "not found" ]; then
  export test_results="$test_results\tpre teardown script: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}pre teardown script: failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_post_teardown" != "not found" ]; then
  export test_results="$test_results\tpost teardown script: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}post teardown script: failed${_CLEAR_TEXT_COLOR}\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
