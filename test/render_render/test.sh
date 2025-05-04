#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh

_valid=$(./shrendd)
echo -e "$_valid"
export test_results="render with just render (by default):\n"
_greeting1=$(yq e ".hello.greeting1" "./target/rendered/test1.yml")
_greeting2=$(yq e ".hello.greeting2" "./target/rendered/test1.yml")
_greeting3=$(yq e ".hello.greeting3" "./target/rendered/test1.yml")
_greeting4=$(yq e ".hello.greeting4" "./target/rendered/test1.yml")
_leelo=$(yq e ".hello.leelodallas" "./target/rendered/test1.yml")
_dallas=$(yq e ".hello.dallas" "./target/rendered/test1.yml")
_fhloston=$(yq e ".hello.fhloston" "./target/rendered/test1.yml")
echo "leelo: $_leelo"
echo "corbin: $_dallas"
echo "fhloston: $_fhloston"
_greetingA=$(yq e ".test.hello" "./config/localdev.yml")
_greetingB=$(yq e ".test.howdy" "./config/config-template.yml" | yq e ".default" -)
_greetingB=$(yq e ".test.howdy" "./config/config-template.yml" | yq e ".default" -)
_multipass=$(yq e ".test.multipass" "./config/config-template.yml" | yq e ".default" - | sed 's/    //g')
_corbin=$(yq e ".test.corbin" "./config/config-template.yml" | yq e ".default" - | sed 's/    //g')
_paradise=$(yq e ".test.multipass2" "./config/localdev.yml" | sed 's/    //g')
echo "multipass: $_multipass"
echo "the real corbin: $_corbin"
echo "flhoston paradise: $_paradise"
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
if [ "$_greeting3" == "$_greetingB" ]; then
  export test_results="$test_results\tgreeting 3: yaml, aka dot notation, \"$_greeting3\" == \"$_greetingB\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}greeting 3: getConfig yaml, aka dot notation, \"$_greeting3\" == \"$_greetingB\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_greeting4" == "$_greetingB" ]; then
  export test_results="$test_results\tgreeting 4: getConfig env, aka uppercase with underscores, \"$_greeting4\" == \"$_greetingB\" passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}greeting 4: getConfig env, aka uppercase with underscores, \"$_greeting4\" == \"$_greetingB\" failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_leelo" == "$_multipass" ]; then
  export test_results="$test_results\tmasked multi-line: multiple lines masked. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}masked multi-line: multiple lines masked. failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_dallas" == "$_corbin" ]; then
  export test_results="$test_results\tunmasked multi-line: multiple lines not masked. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}unmasked multi-line: multiple lines not masked. failed${_CLEAR_TEXT_COLOR}\n"
fi
if [ "$_fhloston" == "$_paradise" ]; then
  export test_results="$test_results\tmasked multi-line: multiple lines from config masked. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}masked multi-line: multiple lines from config masked. failed${_CLEAR_TEXT_COLOR}\n"
fi
_check=$(echo -e "$_valid" | grep "123-peek-a-boo" || echo "not found")
echo "check: $_check"
if [ "$_check" == "not found" ]; then
  export test_results="$test_results\tmasked: all lines masked. passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}masked: all lines masked. failed${_CLEAR_TEXT_COLOR}\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh