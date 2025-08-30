#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./config
echo "attempting extract"
_valid=$(./shrendd -extract)
echo -e "$_valid"
export test_results="template_extract:\n"
_test_hello=$(yq e ".test.hello" "./config/config-template.yml")
_test_world=$(yq e ".test.world" "./config/config-template.yml")
_ralph=$(yq e ".ralph.wiggum" "./config/config-template.yml")
_test_hello_required=$(echo "$_test_hello" | yq e ".required" -)
_test_hello_description=$(echo "$_test_hello" | yq e ".description" -)
_test_hello_sensitive=$(echo "$_test_hello" | yq e ".sensitive" -)
_test_hello_default=$(echo -e "$_test_hello" | grep "#default:" || echo "not found")
_shawn=$(yq e ".psych.spencer.shawn" "./config/config-template.yml")
_lassie=$(yq e ".psych.lassie" "./config/config-template.yml")
_vic=$(yq e ".psych.[\"chief vic\"]" "./config/config-template.yml")
_gus=$(yq e ".psych.[\"burton guster\"]" "./config/config-template.yml")
_pineapple=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./config/config-template.yml")
count=0
_count=$(echo "$_valid" | grep -o "nested reference found:" || echo "not found")
if [ "$_count" != "not found" ]; then
  count=$(echo -e "$_count" | wc -l)
fi
if [ "$count" -gt 3 ] || [ "$count" -lt 3 ]; then
  export test_results="$test_results\t${_TEST_ERROR}warnings: nested reference. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\twarinings: nested reference. passed\n"
fi
if [ "$_test_hello" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}basic key: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tbasic key: stubbed. passed\n"
fi
if [ "$_test_world" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}same line: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tsame line: stubbed. passed\n"
fi
if [ "$_shawn" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}nested key: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tnested key: stubbed. passed\n"
fi
if [ "$_lassie" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}second deploy file: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tsecond deploy file: stubbed. passed\n"
fi
if [ "$_vic" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}deploy file: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tdeploy file: stubbed. passed\n"
fi
if [ "$_gus" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}key with space: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tkey with space: stubbed. passed\n"
fi
if [ "$_pineapple" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}complex key: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tcomplex key: stubbed. passed\n"
fi
if [ "$_test_hello_required" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}stubbed required: required not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tstubbed required: required stubbed. passed\n"
fi
if [ "$_test_hello_description" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}stubbed description: description not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tstubbed description: description stubbed. passed\n"
fi
if [ "$_test_hello_sensitive" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}stubbed sensitive: sensitive not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tstubbed sensitive: sensitive stubbed. passed\n"
fi
if [ "$_test_hello_default" == "not found" ]; then
  export test_results="$test_results\t${_TEST_ERROR}stubbed default: default value (comment) not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tstubbed default: default value (comment) stubbed. passed\n"
fi
if [ "$_ralph" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}key from k8s script: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tkey from k8s script: stubbed. passed\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh