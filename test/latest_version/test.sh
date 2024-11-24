#!/bin/bash
set -euo pipefail

if [ -d ./.shrendd ]; then
  rm -rf ./.shrendd
fi

./shrendd
export test_results_clone="true"
test_results="test results:\n"
test_results="$test_results\tclone passed\n"
export test_result_latest_version="true"
_latest_version=$(yq e ".shrendd.version" "./.shrendd/version.yml")
_current_version=$(yq e ".shrendd.version" "../../version.yml")
echo "running version validations"
if [ "$_latest_version" == "$_current_version" ]; then
  export test_result_latest_version="true"
  test_results="$test_results\tlatest version passed\n"
else
  test_results="$test_results\tlatest version failed\n"
fi

echo -e "$test_results"
