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
cp ./test-init/part2/shrendd.yml .
echo "running part 1"
_part1=$(./shrendd -r -offline)
echo -e "$_part1"
echo "running part 2"
_part2=$(./shrendd -r)
echo -e "$_part2"
export test_results="offline_library:\n"
#if [[ -d "./.shrendd" ]]; then
#  failed ".shrendd does not exist"
#else
#  passed ".shrendd does not exist"
#fi
echo "test fin."
../../build/test/cleanup_shrendd.sh
#source ../../build/test/end.sh