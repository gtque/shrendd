#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
source ../../build/release.sh
#setup broken library
cp ./test-init/part1/shrendd.yml .
echo "init shrendd..."
./shrendd -r
#setup new library that should not be updated yet
echo "updating shrendd.yml for part 2 to update offline_library_lib"
cp ./test-init/part2/shrendd.yml .
echo "running part 1"
_part1=$(./shrendd -r -offline)
echo -e "$_part1"
echo "running part 2"
_part2=$(./shrendd -r)
echo -e "$_part2"
export test_results="offline_library:\n"
_part1_check=$(echo -e "$_part1" | grep "error getting config for app.text.naem" || echo "not found")
_part2_check=$(echo -e "$_part2" | grep "error getting config for app.text.naem" || echo "not found")
if [[ "$_part1_check" == "not found" ]]; then
  failed "app.text.naem library not updated, offline=true"
else
  passed "app.text.naem library not updated, offline=true"
fi
if [[ "$_part2_check" == "not found" ]]; then
  passed "app.text.name after library updated, offline=false"
else
  failed "app.text.name after library updated, offline=false"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh