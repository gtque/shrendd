#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
source ../../build/release.sh
#setup broken library
cp ./test-init/part1/shrendd.yml .
echo "init shrendd..."
./shrendd -init
#setup new library that should not be updated yet
echo "updating shrendd.yml for part 2 to update crib plugin"
cp ./test-init/part2/shrendd.yml .
echo "running part 1"
_part1=$(./shrendd -r -offline)
echo -e "$_part1"
echo "running part 2"
_part2=$(./shrendd -r)
echo -e "$_part2"
export test_results="offline_plugin:\n"
_part1_check1=$(echo -e "$_part1" | grep "crib greeting: well howdy..." || echo "not found")
_part1_check2=$(echo -e "$_part1" | grep "crib greeting: well hello there..." || echo "not found")
_part1_check3=$(echo -e "$_part1" | grep "downloading with curlD...crib" || echo "not found")
_part2_check1=$(echo -e "$_part2" | grep "crib greeting: well howdy..." || echo "not found")
_part2_check2=$(echo -e "$_part2" | grep "crib greeting: well hello there..." || echo "not found")
_part2_check3=$(echo -e "$_part2" | grep "downloading with curlD...crib" || echo "not found")
if [[ "$_part1_check1" == "not found" ]]; then
  failed "crib 1.0.0, well howdy, offline=true"
else
  passed "crib 1.0.0, well howdy, offline=true"
fi
if [[ "$_part1_check2" == "not found" ]]; then
  passed "crib 1.0.0, well hello there, offline=true"
else
  failed "crib 1.0.0, well hello there, offline=true"
fi
if [[ "$_part1_check3" == "not found" ]]; then
  passed "crib 1.0.0, no download, offline=true"
else
  failed "crib 1.0.0, no download, offline=true"
fi
if [[ "$_part2_check1" == "not found" ]]; then
  passed "crib latest, well howdy, offline=false"
else
  failed "crib latest, well howdy, offline=false"
fi
if [[ "$_part2_check2" == "not found" ]]; then
  failed "crib latest, well hello there, offline=false"
else
  passed "crib latest, well hello there, offline=false"
fi
if [[ "$_part2_check3" == "not found" ]]; then
  failed "crib latest, download, offline=false"
else
  passed "crib latest, download, offline=false"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh