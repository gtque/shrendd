#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
source ../../build/release.sh
rm -rf ./boot.shrendd
_before=$(./shrendd -init || echo "finished shrendd with errors...")
_before_check=$(echo -e "${_before}" | grep "wehadababyitsaboy!" || echo "not found")
cp ./test-init/boot.shrendd .
_after=$(./shrendd -init || echo "finished shrendd with errors...")
_after_check=$(echo -e "${_after}" | grep "wehadababyitsaboy!" || echo "not found")
export test_results="bootstrap_init:\n"
if [[ "${_before}" == "finished shrendd with errors..." ]]; then
  failed "before init"
else
  passed "before init"
fi
if [[ "${_before_check}" == "not found" ]]; then
  passed "before boot.shrendd did not run"
else
  failed "before boot.shrendd did not run"
fi
if [[ "${_after}" == "finished shrendd with errors..." ]]; then
  failed "after init"
else
  passed "after init"
fi
if [[ "${_after_check}" == "wehadababyitsaboy!" ]]; then
  passed "after boot.shrendd did run"
else
  failed "after boot.shrendd did run"
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh