#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
if [ $# -gt 0 ]; then
  ./shrendd -r
  exit 0
fi
_shrendd=$(./shrendd -d)
#./shrendd -d
echo -e "$_shrendd"
export test_results="k8s_simple_deploy, configmap only:\n"
_name=$(yq ".app.test.name" ./deploy/config/localdev.yml)
_configmap=$(kubectl -n shrendd-test get cm $_name -o yaml)
_configmap_explicit=$(kubectl -n shrendd-test get cm $_name-imported -o yaml)
_catniss=$(echo -e "$_configmap" | yq e ".data.test2" - | yq e ".pets.cats.[2].name" -)
_configmap2=$(kubectl -n shrendd-test get cm $_name-test -o yaml)
_testscript=$(echo -e "$_configmap2" | yq e ".data.[\"doSomething.sh\"]" -)
_testscript_noname=$(echo -e "$_configmap_explicit" | yq e ".data.[\"helloworld.sh\"]" -)
_testscript_givenname=$(echo -e "$_configmap_explicit" | yq e ".data.[\"kitty.sh\"]" -)
_pie=$(echo -e "$_configmap" | yq e ".data.test6" - | yq e ".pies" - | yq e ".[1].name" -)
echo "************************************"
echo "tear down tests"
_shrendd_t=$(./shrendd -t)
echo -e "$_shrendd_t"
_teardown=$(kubectl -n shrendd-test get cm $_name -o yaml || echo "not found")
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
if [[ "$_testscript_noname" == *"echo \"hello, world!\""* ]]; then
  export test_results="$test_results\tk8s script import no name: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}k8s script import no name: failed${_CLEAR_TEXT_COLOR}\n"
fi
if [[ "$_testscript_givenname" == *"echo \"Bake him away, toys.\""* ]]; then
  export test_results="$test_results\tk8s script import given name: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}k8s script import given name: failed${_CLEAR_TEXT_COLOR}\n"
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
