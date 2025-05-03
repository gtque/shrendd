#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -f ./shrendd
cp ./test-init/shrendd ./
export SHRENDD_TEXT_INFO_RED='\033[0;31m'
export SHRENDD_TEXT_INFO='$SHRENDD_TEXT_INFO_RED'
echo "running shrendd"
./shrendd -init
export test_results="upshrendd valid and already uptodate:\n"
echo "running valid upshrendd"
_valid=$(./.shrendd/upshrendd || echo "failed to upshrendd completely!")
echo "running uptodate upshrendd"
_uptodate=$(./.shrendd/upshrendd || echo "failed to upshrendd the second time completely!")
echo "checking upshrendd"
if [ "$_valid" == "failed to upshrendd completely!" ]; then
  export test_results="$test_results\tvalid upshrendd: something went horribly wrong and needs to be manually checked. failed\n"
else
  _check=$(echo -e "$_valid" | grep "does not match target version" || echo "not found")
  if [ "$_check" == "not found" ]; then
    export test_results="$test_results\tvalid upshrendd: failed to detect a difference and perform upgrade. failed\n"
  else
    export test_results="$test_results\tvalid upshrendd: shrendd was upgraded. passed\n"
  fi
fi
if [ "$_uptodate" == "failed to upshrendd the second time completely!" ]; then
  export test_results="$test_results\tuptodate upshrendd: something went horribly wrong and needs to be manually checked. failed\n"
else
  _check=$(echo -e "$_uptodate" | grep "seems shrendd is already up to date" || echo "not found")
  if [ "$_check" == "not found" ]; then
    export test_results="$test_results\t${_TEST_ERROR}uptodate upshrendd: failed to detect a and perform upgrade. failed${_CLEAR_TEXT_COLOR}\n"
  else
    export test_results="$test_results\t${_TEST_PASS}uptodate upshrendd: shrendd is up-to-date. passed${_CLEAR_TEXT_COLOR}\n"
  fi
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh