#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh

./shrendd
export test_results="render with only template test results:\n"
_greeting1=$(yq e ".hello.greeting1" "./deploy/test/rendered/test1.yml")
_greeting2=$(yq e ".hello.greeting2" "./deploy/test/rendered/test1.yml")
_greeting3=$(yq e ".hello.greeting3" "./deploy/test/rendered/test1.yml")
_greeting4=$(yq e ".hello.greeting4" "./deploy/test/rendered/test1.yml")
_greetingA=$(yq e ".test.hello" "./config/config-template.yml" | yq e ".default" -)
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
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh