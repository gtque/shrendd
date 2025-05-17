#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./config
mkdir ./config
cp ./test-init/config-template.yml ./config/.
echo "attempting extract"
_i_should_not_expected=$(yq e ".i.should.not" "./test-init/config-template.yml")
_i_should_not_actual_before=$(yq e ".i.should.not" "./config/config-template.yml")
_i_should_actual_before=$(yq e ".i.should.exist" "./config/config-template.yml")
_valid=$(./shrendd -extract)
echo -e "$_valid"
export test_results="template extract:\n"
_i_should_not_actual_after=$(yq e ".i.should.not" "./config/config-template.yml")
_i_should_actual_after=$(yq e ".i.should.exist" "./config/config-template.yml")
_test_hello=$(yq e ".test.hello" "./config/config-template.yml")
_test_hello_required=$(echo "$_test_hello" | yq e ".required" -)
_test_hello_description=$(echo "$_test_hello" | yq e ".description" -)
_test_hello_sensitive=$(echo "$_test_hello" | yq e ".sensitive" -)
_test_hello_default=$(echo -e "$_test_hello" | grep "#default:" || echo "not found")
_shawn=$(yq e ".psych.spencer.shawn" "./config/config-template.yml")
_shawn_sanity=$(yq e ".psych.spencer.shawn" "./test-init/config-template.yml")
_gus=$(yq e ".psych.[\"burton guster\"]" "./config/config-template.yml")
_gus_default_actual=$(echo "$_gus" | yq e ".default" -)
_gus_default_expected=$(yq e ".psych.[\"burton guster\"]" "./test-init/config-template.yml" | yq e ".default" -)
_gus_description_actual=$(echo "$_gus" | yq e ".description" -)
_gus_description_expected=$(yq e ".psych.[\"burton guster\"]" "./test-init/config-template.yml" | yq e ".description" -)
_pineapple=$(yq e ".psych.[\"fru it\"].[\"pin-a p_pl e\"]" "./config/config-template.yml")
if [ "$_test_hello" == "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}basic key: not stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tbasic key: stubbed. passed\n"
fi
#it should not be present in the inital config-template
if [ "$_shawn_sanity" != "null" ]; then
  export test_results="$test_results\t${_TEST_ERROR}nested key: sanity check: stubbed. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tnested key: sanity check: not stubbed. passed\n"
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
if [ "$_gus_default_expected" != "null" ] && [ "$_gus_default_expected" == "$_gus_default_actual" ]; then
  export test_results="$test_results\tpre stubbed default: default matched. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}pre stubbed default: default matched. failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_gus_description_expected" != "null" ] && [ "$_gus_description_expected" == "$_gus_description_actual" ]; then
  export test_results="$test_results\tpre stubbed description: description matched. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}pre stubbed description: description matched. failed${_CLEAR_TEXT_COLOR}\n"
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
if [ "$_i_should_actual_after" == "$_i_should_actual_before" ]; then
  export test_results="$test_results\tindirect key: is present. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}indirect key: is present. failed${_CLEAR_TEXT_COLOR}\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh