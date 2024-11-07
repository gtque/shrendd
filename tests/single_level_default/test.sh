#!/bin/bash
set -euo pipefail

./shrendd
test_results="test results:\n"
test_setup="false"
if [ "$(cat ./deploy/test/rendered/test1.txt)" == "hello, world!" ]; then
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

echo -e "$test_results"
