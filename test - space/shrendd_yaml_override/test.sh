#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
export SHREND_YML="./alt_shrendd.yml"
./shrendd -init
export test_results_clone="true"
export test_results="shrendd.yml override:\n"
export test_results="$test_results\tclone passed\n"
export test_result_latest_version="true"
_latest_version=$(yq e ".shrendd.version" "./.shrendd/version.yml")
_current_version=$(yq e ".shrendd.version" "./alt_shrendd.yml")
echo "running version validations"
if [ "$_latest_version" == "$_current_version" ]; then
  export test_result_latest_version="true"
  export test_results="$test_results\t${_TEST_PASS}version \"$_latest_version\" == \"$_current_version\" passed${_CLEAR_TEXT_COLOR}\n"
else
  export test_results="$test_results\t${_TEST_ERROR}version \"$_latest_version\" == \"$_current_version\" failed${_CLEAR_TEXT_COLOR}\n"
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh