#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
rm -f ./deploy/config/config-template.yml
rm -rf ~/.shrendd/cache/shrendd-lib-test
rm -f ./shrendd.yml
cp ./test-init/shrendd_1.yml ./shrendd.yml
if [ $# -gt 0 ]; then
  ./shrendd -extract
  echo "debug test end!!!"
  exit 0
fi
echo "**************** Phase 1 ********************"
_shrendd1=$(./shrendd -extract || echo "phase 1 failed...")
echo -e "$_shrendd1"
echo "**************** Phase 2 ********************"
./shrendd -r --config test_1.yml
_shrendd2=$(./shrendd -r -S --config test_1.yml || echo "phase 2 failed...")
echo -e "$_shrendd2"
echo "*************** Phase 3 *********************"
rm -f ./shrendd.yml
cp ./test-init/shrendd_2.yml ./shrendd.yml
_shrendd3=$(./shrendd -extract || echo "phase 3 failed...")
echo -e "$_shrendd3"
echo "*************** Phase 4 *********************"
_shrendd4=$(./shrendd -r -S --config test_2.yml || echo "phase 4 failed...")
echo -e "$_shrendd4"
export test_results="template_remote_library:\n"
_r1=$(echo "$_shrendd1" | grep "phase 1 failed..." || echo "passed")
if [ "$_r1" == "passed" ]; then
  passed "phase 1"
else
  failed "phase 1"
fi
_r2=$(echo "$_shrendd2" | grep "phase 2 failed..." || echo "passed")
if [ "$_r2" == "passed" ]; then
  passed "phase 2"
else
  failed "phase 2"
fi
_r3=$(echo "$_shrendd3" | grep "phase 3 failed..." || echo "passed")
if [ "$_r3" == "passed" ]; then
  passed "phase 3"
else
  failed "phase 3"
fi
_r4=$(echo "$_shrendd4" | grep "phase 4 failed..." || echo "passed")
if [ "$_r4" == "passed" ]; then
  passed "phase 4"
else
  failed "phase 4"
fi
#_test_hello=$(yq e ".test.hello" "./config/config-template.yml")
#_name=$(yq ".app.test.name" ./deploy/config/localdev.yml)
#_configmap=$(kubectl -n shrendd-test get cm $_name -o yaml)
#_configmap_explicit=$(kubectl -n shrendd-test get cm $_name-imported -o yaml)
#_catniss=$(echo -e "$_configmap" | yq e ".data.test2" - | yq e ".pets.cats.[2].name" -)
#_configmap2=$(kubectl -n shrendd-test get cm $_name-test -o yaml)
#_testscript=$(echo -e "$_configmap2" | yq e ".data.[\"doSomething.sh\"]" -)
#_testscript_noname=$(echo -e "$_configmap_explicit" | yq e ".data.[\"helloworld.sh\"]" -)
#_testscript_givenname=$(echo -e "$_configmap_explicit" | yq e ".data.[\"kitty.sh\"]" -)
#_pie=$(echo -e "$_configmap" | yq e ".data.test6" - | yq e ".pies" - | yq e ".[1].name" -)
#echo "************************************"
#echo "tear down tests"
#_shrendd_t=$(./shrendd -t)
#echo -e "$_shrendd_t"
#_teardown=$(kubectl -n shrendd-test get cm $_name -o yaml || echo "not found")
#_pre_teardown=$(echo -e "$_shrendd_t" | grep "I run before anything of the rest of the teardown scripts, even before the standard teardown" || echo "not found")
#echo "first pre check: $_pre_teardown"
#_pre_teardown=$(echo -e "$_pre_teardown" | grep -v "echo" || echo "not found")
#echo "second pre check: $_pre_teardown"
#_post_teardown=$(echo -e "$_shrendd_t" | grep "I run after the standard teardown." || echo "not found")
#echo "first post check: $_post_teardown"
#_post_teardown=$(echo -e "$_post_teardown" | grep -v "echo" || echo "not found")
#echo "second post check: $_post_teardown"
#echo "teardown finished"
#echo "cat: $_catniss"
#echo "pie: $_pie"
#echo "teardown: $_teardown"
#echo "$_testscript"
#if [ "$_catniss" == "catniss" ]; then
#  export test_results="$test_results\tk8s_to_yaml: passed\n"
#else
#  export test_results="$test_results\t${_TEST_ERROR}k8s_to_yaml: failed${_CLEAR_TEXT_COLOR}\n"
#fi
#if [ "$_pie" == "pecan" ]; then
#  export test_results="$test_results\tnested with array: passed\n"
#else
#  export test_results="$test_results\t${_TEST_ERROR}nested with array: failed${_CLEAR_TEXT_COLOR}\n"
#fi
#if [[ "$_testscript" == *"I'm a brick"* ]]; then
#  export test_results="$test_results\tk8s script render: passed\n"
#else
#  export test_results="$test_results\t${_TEST_ERROR}k8s script render: failed${_CLEAR_TEXT_COLOR}\n"
#fi
#if [[ "$_testscript_noname" == *"echo \"hello, world!\""* ]]; then
#  export test_results="$test_results\tk8s script import no name: passed\n"
#else
#  export test_results="$test_results\t${_TEST_ERROR}k8s script import no name: failed${_CLEAR_TEXT_COLOR}\n"
#fi
#if [[ "$_testscript_givenname" == *"echo \"Bake him away, toys.\""* ]]; then
#  export test_results="$test_results\tk8s script import given name: passed\n"
#else
#  export test_results="$test_results\t${_TEST_ERROR}k8s script import given name: failed${_CLEAR_TEXT_COLOR}\n"
#fi
#if [ "$_teardown" == "not found" ]; then
#  export test_results="$test_results\ttear down: passed\n"
#else
#  export test_results="$test_results\t${_TEST_ERROR}tear down: failed${_CLEAR_TEXT_COLOR}\n"
#fi
#if [ "$_pre_teardown" != "not found" ]; then
#  export test_results="$test_results\tpre teardown script: passed\n"
#else
#  export test_results="$test_results\t${_TEST_ERROR}pre teardown script: failed${_CLEAR_TEXT_COLOR}\n"
#fi
#if [ "$_post_teardown" != "not found" ]; then
#  export test_results="$test_results\tpost teardown script: passed\n"
#else
#  export test_results="$test_results\t${_TEST_ERROR}post teardown script: failed${_CLEAR_TEXT_COLOR}\n"
#fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
