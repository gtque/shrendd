#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./folder/deploy/test/generated
rm -rf ./folder/deploy/k8s/generated
./shrendd --module folder -r
echo "render should be finished!"
export test_results="custom module shrendd.yml file:\n"
_greeting1=$(yq e ".hello.greeting1" "./folder/deploy/test/generated/test1.yml")
_greeting2=$(yq e ".hello.greeting2" "./folder/deploy/test/generated/test1.yml")
_greeting3=$(yq e ".hello.greeting3" "./folder/deploy/test/generated/test1.yml")
_greeting4=$(yq e ".hello.greeting4" "./folder/deploy/test/generated/test1.yml")
_greetingA=$(yq e ".test.hello" "./config/localdev.yml")
echo "checking rendering"
if [ "$_greeting1" == "$_greetingA" ]; then
  export test_results="$test_results\tgreeting 1: env, aka uppercase with underscores, \"$_greeting1\" == \"$_greetingA\" passed\n"
else
  export test_results="$test_results\tgreeting 1: env, aka uppercase with underscores, \"$_greeting1\" == \"$_greetingA\" failed\n"
fi
if [ "$_greeting2" == "$_greetingA" ]; then
  export test_results="$test_results\tgreeting 2: yaml, aka dot notation, \"$_greeting2\" == \"$_greetingA\" passed\n"
else
  export test_results="$test_results\tgreeting 2: yaml, aka dot notation, \"$_greeting2\" == \"$_greetingA\" failed\n"
fi
if [ "$_greeting3" == "$_greetingA" ]; then
  export test_results="$test_results\tgreeting 3: yaml, aka dot notation, \"$_greeting3\" == \"$_greetingA\" passed\n"
else
  export test_results="$test_results\tgreeting 3: getConfig yaml, aka dot notation, \"$_greeting3\" == \"$_greetingA\" failed\n"
fi
if [ "$_greeting4" == "$_greetingA" ]; then
  export test_results="$test_results\tgreeting 4: getConfig env, aka uppercase with underscores, \"$_greeting4\" == \"$_greetingA\" passed\n"
else
  export test_results="$test_results\tgreeting 4: getConfig env, aka uppercase with underscores, \"$_greeting4\" == \"$_greetingA\" failed\n"
fi
if [ -d "./folder/deploy/k8s/generated" ]; then
  export test_results="$test_results\t${_TEST_ERROR}k8s render directory: 'generated' exists but it should not. failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\tk8s render directory: 'generated' does not exist. passed\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh