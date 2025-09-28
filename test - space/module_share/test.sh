#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./folder/deploy/test/generated
rm -rf ./other/deploy/test/pudding
_shrend_results=$(./shrendd --module folder --module other -r)
_shrend_folder=$(echo "$_shrend_results" | sed -z "s/rendering: other.*//g")
_shrend_other=$(echo "$_shrend_results" | sed -z "s/rendering: folder.*rendering: other//g")
echo -e "$_shrend_results"
echo "render should be finished!"
export test_results="share config between modules:\n"
_greeting1=$(yq e ".hello.greeting1" "./folder/deploy/test/generated/test1.yml")
_greeting2=$(yq e ".hello.greeting2" "./folder/deploy/test/generated/test1.yml")
_greeting3=$(yq e ".hello.greeting3" "./folder/deploy/test/generated/test1.yml")
_greeting4=$(yq e ".hello.greeting4" "./folder/deploy/test/generated/test1.yml")
_greeting1b=$(yq e ".hello.greeting1" "./other/deploy/test/pudding/test1.yml")
_food1b=$(yq e ".hello.food2" "./other/deploy/test/pudding/test1.yml")
_greetingA=$(yq e ".test.hello" "./config/localdev.yml")
_foodA=$(yq e ".test.dessert" "./config/localdev.yml")
_greetingB=$(yq e ".test.hello" "./other/config/localdev.yml")
_foodB=$(yq e ".test.dessert" "./other/config/localdev.yml")
echo "checking rendering"
if [ "$_greeting1" == "$_greetingA" ]; then
  export test_results="$test_results\tgreeting 1: env, aka uppercase with underscores, \"$_greeting1\" == \"$_greetingA\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}greeting 1: env, aka uppercase with underscores, \"$_greeting1\" == \"$_greetingA\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_greeting2" == "$_greetingA" ]; then
  export test_results="$test_results\tgreeting 2: yaml, aka dot notation, \"$_greeting2\" == \"$_greetingA\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}greeting 2: yaml, aka dot notation, \"$_greeting2\" == \"$_greetingA\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_greeting3" == "$_greetingA" ]; then
  export test_results="$test_results\tgreeting 3: yaml, aka dot notation, \"$_greeting3\" == \"$_greetingA\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}greeting 3: getConfig yaml, aka dot notation, \"$_greeting3\" == \"$_greetingA\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_greeting4" == "$_greetingA" ]; then
  export test_results="$test_results\tgreeting 4: getConfig env, aka uppercase with underscores, \"$_greeting4\" == \"$_greetingA\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}greeting 4: getConfig env, aka uppercase with underscores, \"$_greeting4\" == \"$_greetingA\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ -d "./folder/deploy/k8s/generated" ]; then
  export test_results="$test_results\t${_TEST_ERROR}k8s render directory: 'generated' exists but it should not. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tk8s render directory: 'generated' does not exist. passed\n"
fi
_check=$(echo -e "$_shrend_folder" | grep "error getting" || echo "not found")
if [ "$_check" == "not found" ]; then
  export test_results="$test_results\tfolder: had no errors rendering. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}folder: had errors rendering. failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_greeting1b" == "$_greetingB" ]; then
  export test_results="$test_results\tgreeting 1b: custom module localdev.yml, \"$_greeting1b\" == \"$_greetingB\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}greeting 1b: custom module localdev.yml, \"$_greeting1b\" == \"$_greetingB\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_food1b" == "$_foodA" ]; then
  export test_results="$test_results\tfood 1b: shared the config, \"$_food1b\" == \"$_foodA\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}food 1b: shared the config, \"$_food1b\" == \"$_foodA\" failed${_CLEAR_TEXT_COLOR}\n"
fi
_check=$(echo -e "$_shrend_other" | grep "error getting" || echo "not found")
if [ "$_check" == "not found" ]; then
  export test_results="$test_results\tother: had no errors rendering, and that was expected. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}other: had errors rendering, and that was unexpected. failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_greetingA" == "$_greetingB" ]; then
  export test_results="$test_results\t${_TEST_ERROR}sanity check: A != B, \"$_greetingA\" != \"$_greetingB\" failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tsanity check: A != B, \"$_greetingA\" != \"$_greetingB\" passed\n"
fi
if [ "$_foodA" == "$_foodB" ]; then
  export test_results="$test_results\t${_TEST_ERROR}sanity check: foodA != foodB, \"$_foodA\" != \"$_foodB\" failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tsanity check: foodA != foodB, \"$_foodA\" != \"$_foodB\" passed\n"
fi
if [ "$_foodB" == "null" ]; then
  export test_results="$test_results\tsanity check: foodB should be null, \"$_foodB\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}sanity check: foodB should be null, \"$_foodB\" failed${_CLEAR_TEXT_COLOR}\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh