#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./config
mkdir ./config
cp ./test-init/config-template.yml ./config/.
cp ./test-init/testspawn.yml ./config/.
_i_should_not_expected=$(yq e ".i.should.not" "./test-init/testspawn.yml")
_i_should_not_actual_before=$(yq e ".i.should.not" "./config/testspawn.yml")
echo "attempting spawn"
_valid=$(./shrendd --spawn testspawn.yml)
echo -e "$_valid"
_i_should_not_actual_after=$(yq e ".i.should.not" "./config/testspawn.yml")
export test_results="template extract:\n"
_test_array=$(yq e ".test.array" "./config/config-template.yml")
_test_array_age_actual=$(yq e ".test.array.[2].age" "./config/testspawn.yml")
_test_array_age_expected=$(echo "$_test_array" | yq e ".default.[2].age" -)
_test_array_age_description=$(echo "$_test_array" | yq e ".description" -)
_shawn=$(yq e ".psych.spencer.shawn" "./config/config-template.yml")
_shawn_expected=$(echo "$_shawn" | yq e ".default" -)
_pineapple=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./config/testspawn.yml")
if [ "$_shawn_expected" == "null" ]; then
  _shawn_expected=""
fi
_shawn_actual=$(yq e ".psych.spencer.shawn" "./config/testspawn.yml")
_gus=$(yq e ".psych.[\"burton guster\"]" "./config/config-template.yml")
#_gus_expected=$(echo "$_gus" | yq e ".default" -)
_gus_actual=$(yq e ".psych.[\"burton guster\"]" "./config/testspawn.yml")
_gus_not_expected=$(yq e ".psych.[\"burton guster\"]" "./test-init/testspawn.yml")
_gus_expected=$(yq e ".psych.[\"burton guster\"]" "./test-init/config-template.yml" | yq e ".default" -)
if [ "$_gus_expected" == "null" ]; then
  _gus_expected=""
fi
_gus_actual=$(yq e ".psych.[\"burton guster\"]" "./config/testspawn.yml")
_pineapple=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./config/config-template.yml")
#_pineapple_expected=$(echo "$_pineapple" | yq e ".default" -)
_pineapple_expected=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./test-init/testspawn.yml")
_pineapple_not_expected=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./test-init/config-template.yml" | yq e ".default" -)
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
#if this failed, make sure "burton guster" does not exist in the test-init/testspawn.yml
if [ "$_gus_expected" == "$_gus_actual" ] && [ "$_gus_expected" != "$_gus_not_expected" ]; then
  export test_results="$test_results\tspace in key: set. \"$_gus_expected\" == \"$_gus_actual\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}space in key: not equal. \"$_gus_expected\" == \"$_gus_actual\" failed${_CLEAR_TEXT_COLOR}\n"
fi
#if this failed, make sure the initial value is not set to "pen" in test-init/testspawn.yml
if [ "$_pineapple_expected" == "$_pineapple_actual" ] && [ "$_pineapple_expected" != "$_pineapple_not_expected" ]; then
  export test_results="$test_results\tnested complex key: set. \"$_pineapple_expected\" == \"$_pineapple_actual\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}nested complex key: not equal. \"$_pineapple_expected\" == \"$_pineapple_actual\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_i_should_not_expected" != "null" ] && [ "$_i_should_not_expected" != "$_i_should_not_actual_before" ]; then
  export test_results="$test_results\t${_TEST_ERROR}removed key: sanity check: setup is invalid. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tremoved key: sanity check: setup valid. passed\n"
fi
if [ "$_i_should_not_actual_after" != "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}removed key: stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tremoved key: not stubbed. passed\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh