#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./config
echo "attempting extract"
_valid=$(./shrendd -extract)
echo -e "$_valid"
export test_results="template extract:\n"
_test_hello=$(yq e ".test.hello" "./config/config-template.yml")
_test_hello_required=$(echo "$_test_hello" | yq e ".required" -)
_test_hello_description=$(echo "$_test_hello" | yq e ".description" -)
_test_hello_sensitive=$(echo "$_test_hello" | yq e ".sensitive" -)
_test_hello_default=$(echo -e "$_test_hello" | grep "#default:" || echo "not found")
_shawn=$(yq e ".psych.spencer.shawn" "./config/config-template.yml")
_gus=$(yq e ".psych.[\"burton guster\"]" "./config/config-template.yml")
_pineapple=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./config/config-template.yml")
if [ "$_test_hello" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}basic key: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tbasic key: stubbed. passed\n"
fi
if [ "$_shawn" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}nested key: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tnested key: stubbed. passed\n"
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
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh