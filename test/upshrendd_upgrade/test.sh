#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
./shrendd -r
echo "faking out version"
cp -r ./test-init/dot_shrendd/version.yml ./.shrendd/version.yml
sed -i "s/_UPSHRENDD_VERSION=\".*\"/_UPSHRENDD_VERSION=\"-1.0.0-dev\"/g" "./shrendd"
export test_results="upshrendd upgrade:\n"
echo "running upgrade upshrendd"
_valid=$(./.shrendd/upshrendd || echo "failed to upshrendd completely!")
echo "checking upshrendd"
if [ "$_valid" == "failed to upshrendd completely!" ]; then
  export test_results="$test_results\tupgrade upshrendd: something went horribly wrong and needs to be manually checked. failed\n"
else
  echo "checking $_valid"
  _check=$(echo -e "$_valid" | grep "You are upgrading, but it seems there are breaking changes" || echo "not found")
  if [ "$_check" == "not found" ]; then
    export test_results="$test_results\tupgrade upshrendd: failed to detect an incompatible upgrade. failed\n"
  else
    export test_results="$test_results\tupgrade upshrendd: shrendd detected an upgrade incompatibility correctly. pass\n"
  fi
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh