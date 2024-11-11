#!/bin/bash
set -euo pipefail

./shrendd
test_results="test results:\n"
test_setup="false"
_expected=$(cat << EOF
hello, world!
sup, snart?
message 1: spaghetti
message 2: sauce
EOF)

test_render="false"
_actual="$(cat ./deploy/test/rendered/test1.txt)"
#_actual="$(echo "$_actual")"
#_expected="$(echo -e "$_expected")"
if [[ "$_actual" == "$_expected" ]]; then
  test_render="true"
  test_results="$test_results\tsetup passed\n"
else
  test_results="$test_results\tsetup failed\n"
fi

./shrendd -t
test_teardown="false"
echo "teardown finished"
if [ -d ./deploy/test/rendered ]; then
  test_results="$test_results\ttear down failed\n"
else
  test_teardown="true"
  test_results="$test_results\ttear down passed\n"
fi

export test_result_single_level_default_setup="$test_render"
export test_result_single_level_default_teardown="$test_teardown"
echo -e "actual: $_actual"
echo -e "expected: $_expected"
echo -e "$test_results"
