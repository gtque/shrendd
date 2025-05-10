#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -f ./config/testspawn.yml
echo "attempting spawn"
_valid=$(./shrendd --spawn testspawn.yml)
echo -e "$_valid"
export test_results="template extract:\n"
_test_array=$(yq e ".test.array" "./config/config-template.yml")
_test_array_age_actual=$(yq e ".test.array.[2].age" "./config/testspawn.yml")
_test_array_age_expected=$(echo "$_test_array" | yq e ".default.[2].age" -)
_test_array_age_description=$(echo "$_test_array" | yq e ".description" -)
#_test_hello_description=$(echo "$_test_hello" | yq e ".description" -)
#_test_hello_sensitive=$(echo "$_test_hello" | yq e ".sensitive" -)
#_test_hello_default=$(echo -e "$_test_hello" | grep "#default:" || echo "not found")
_shawn=$(yq e ".psych.spencer.shawn" "./config/config-template.yml")
_shawn_expected=$(echo "$_shawn" | yq e ".default" -)
if [ "$_shawn_expected" == "null" ]; then
  _shawn_expected=""
fi
_shawn_actual=$(yq e ".psych.spencer.shawn" "./config/testspawn.yml")
_gus=$(yq e ".psych.[\"burton guster\"]" "./config/config-template.yml")
_gus_expected=$(echo "$_gus" | yq e ".default" -)
if [ "$_gus_expected" == "null" ]; then
  _gus_expected=""
fi
_gus_actual=$(yq e ".psych.[\"burton guster\"]" "./config/testspawn.yml")
_pineapple=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./config/config-template.yml")
_pineapple_expected=$(echo "$_pineapple" | yq e ".default" -)
if [ "$_pineapple_expected" == "null" ]; then
  _pineapple_expected=""
fi
_pineapple_actual=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./config/testspawn.yml")
if [ "$_test_array_age_expected" == "$_test_array_age_actual" ]; then
  export test_results="$test_results\tarray value: set. \"$_test_array_age_expected\" == \"$_test_array_age_actual\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}array value: not equal. \"$_test_array_age_expected\" == \"$_test_array_age_actual\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_shawn_expected" == "$_shawn_actual" ]; then
  export test_results="$test_results\tno default value: set. \"$_shawn_expected\" == \"$_shawn_actual\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}no default value: not equal. \"$_shawn_expected\" == \"$_shawn_actual\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_gus_expected" == "$_gus_actual" ]; then
  export test_results="$test_results\tspace in key: set. \"$_gus_expected\" == \"$_gus_actual\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}space in key: not equal. \"$_gus_expected\" == \"$_gus_actual\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_pineapple_expected" == "$_pineapple_actual" ]; then
  export test_results="$test_results\tnested complex key: set. \"$_pineapple_expected\" == \"$_pineapple_actual\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}nested complex key: not equal. \"$_pineapple_expected\" == \"$_pineapple_actual\" failed${_CLEAR_TEXT_COLOR}\n"
fi
#if [ "$_shawn" == "null" ]; then
#  export test_results="$test_results\t${_TEST_ERROR}nested key: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
#else
#  export test_results="$test_results\tnested key: stubbed. passed\n"
#fi
#if [ "$_gus" == "null" ]; then
#  export test_results="$test_results\t${_TEST_ERROR}key with space: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
#else
#  export test_results="$test_results\tkey with space: stubbed. passed\n"
#fi
#if [ "$_pineapple" == "null" ]; then
#  export test_results="$test_results\t${_TEST_ERROR}complex key: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
#else
#  export test_results="$test_results\tcomplex key: stubbed. passed\n"
#fi
#if [ "$_test_hello_required" == "null" ]; then
#  export test_results="$test_results\t${_TEST_ERROR}stubbed required: required not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
#else
#  export test_results="$test_results\tstubbed required: required stubbed. passed\n"
#fi
#if [ "$_test_hello_description" == "null" ]; then
#  export test_results="$test_results\t${_TEST_ERROR}stubbed description: description not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
#else
#  export test_results="$test_results\tstubbed description: description stubbed. passed\n"
#fi
#if [ "$_test_hello_sensitive" == "null" ]; then
#  export test_results="$test_results\t${_TEST_ERROR}stubbed sensitive: sensitive not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
#else
#  export test_results="$test_results\tstubbed sensitive: sensitive stubbed. passed\n"
#fi
#if [ "$_test_hello_default" == "not found" ]; then
#  export test_results="$test_results\t${_TEST_ERROR}stubbed default: default value (comment) not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
#else
#  export test_results="$test_results\tstubbed default: default value (comment) stubbed. passed\n"
#fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh