#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
source ../../build/release.sh
./shrendd -init
export test_results_clone="true"
export test_results="version_latest_specified:\n"
export test_results="$test_results\tclone passed\n"
export test_result_latest_version="true"
_latest_version=$(yq e ".shrendd.version" "./.shrendd/version.yml")
latest_release ./.shrendd/latestrelease.json
_current_version="$_RELEASE"
echo "running version validations"
if [ "$_latest_version" == "$_current_version" ]; then
  export test_result_latest_version="true"
   passed "$test_results\tversion \"$_latest_version\" == \"$_current_version\""
else
  failed "$test_results\tversion \"$_latest_version\" == \"$_current_version\""
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh