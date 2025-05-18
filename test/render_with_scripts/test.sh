#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
./shrendd
export test_results="test results:\n"
test_setup="false"
_expected=$(cat << EOF
hello, world!
sup, snart?
message 1: spaghetti
message 2: sauce
EOF)

test_render="false"
_actual="$(cat ./deploy/target/test/rendered/test1.txt)"
if [[ "$_actual" == "$_expected" ]]; then
  test_render="true"
  export test_results="$test_results\tsetup: passed\n"
else
  export test_results="$test_results\t${_TEST_ERROR}setup: failed${_CLEAR_TEXT_COLOR}\n"
fi
echo "************************************"
echo "tear down tests"
./shrendd -t
echo "teardown finished"
if [ -d ./deploy/target/test/rendered ]; then
  export test_results="$test_results\t${_TEST_ERROR}tear down: failed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\ttear down: passed\n"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
