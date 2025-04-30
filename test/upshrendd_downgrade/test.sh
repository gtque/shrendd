#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
./shrendd -r
echo "faking out version"
cp -f ./test-init/dot_shrendd/version.yml ./.shrendd/.
export test_results="upshrendd downgrade:\n"
echo "running downgrade upshrendd"
_valid=$(./.shrendd/upshrendd || echo "failed to upshrendd completely!")
echo "checking upshrendd"
if [ "$_valid" == "failed to upshrendd completely!" ]; then
  export test_results="$test_results\tdowngrade upshrendd: something went horribly wrong and needs to be manually checked. failed\n"
else
  _check=$(echo -e "$_valid" | grep "It appears as though you are downgrading." || echo "not found")
  if [ "$_check" == "not found" ]; then
    export test_results="$test_results\tdowngrade upshrendd: failed to detect an incompatible downgrade. failed\n"
  else
    export test_results="$test_results\tdowngrade upshrendd: shrendd detected a downgrade incompatibility correctly. pass\n"
  fi
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh