#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
./shrendd -init
echo "faking out version"
cp -f ./test-init/dot_shrendd/version.yml ./.shrendd/.
sed -i "s/_UPSHRENDD_VERSION=\".*\"/_UPSHRENDD_VERSION=\"0.1.0-dev\"/g" "./shrendd"
export test_results="upshrendd downgrade:\n"
echo "running downgrade upshrendd"
_valid=$(./.shrendd/upshrendd || echo "failed to upshrendd completely!")
echo -e "checking upshrendd:\n$_valid"
if [ "$_valid" == "failed to upshrendd completely!" ]; then
  export test_results="$test_results\tdowngrade upshrendd: something went horribly wrong and needs to be manually checked. failed\n"
else
  _check=$(echo -e "$_valid" | grep "It appears as though you are downgrading." || echo "not found")
  if [ "$_check" == "not found" ]; then
    export test_results="$test_results\tdowngrade upshrendd: failed to detect an incompatible downgrade. failed\n"
  else
    export test_results="$test_results\tdowngrade upshrendd: shrendd detected a downgrade incompatibility correctly. passed\n"
  fi
  _check=$(echo -e "$_valid" | grep "'-f'" || echo "not found")
  if [ "$_check" == "not found" ]; then
    export test_results="$test_results\tdowngrade upshrendd: failed to print message about '-f' parameter. failed\n"
  else
    export test_results="$test_results\tdowngrade upshrendd: mentioned '-f'. passed\n"
  fi
fi
_valid=$(./.shrendd/upshrendd -f || echo "failed to upshrendd completely!")
if [ "$_valid" == "failed to upshrendd completely!" ]; then
  export test_results="$test_results\tdowngrade upshrendd: something went horribly wrong and needs to be manually checked. failed\n"
else
  _check=$(echo -e "$_valid" | grep "downloading with" || echo "not found")
  if [ "$_check" == "not found" ]; then
    export test_results="$test_results\tdowngrade upshrendd: failed to detect a difference and perform upgrade. failed\n"
  else
    export test_results="$test_results\tdowngrade upshrendd: shrendd was upgraded. passed\n"
  fi
    _check=$(echo -e "$_valid" | grep "You are downgrading and an incompatibility was detected. The downgrade will be forced, as you wish." || echo "not found")
  if [ "$_check" == "not found" ]; then
    export test_results="$test_results\tdowngrade upshrendd: failed to detect an incompatible upgrade with force enabled. failed\n"
  else
    export test_results="$test_results\tdowngrade upshrendd: shrendd detected an upgrade incompatibility correctly with force enabled. passed\n"
  fi
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh