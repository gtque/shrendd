#!/bin/bash
set -euo pipefail

#setup test source
source ../../build/test/start.sh
../../build/test/init_shrendd.sh
source ../../build/release.sh
#do anything else you need to do before running shrendd
#make sure to clean up any lingering files from previous runs that could cause a false positive/negative
#if present when the test runs.

#execute shrendd, update the shrendd parameters as necessary
_part1=$(./shrendd -init || echo "finished shrendd with errors...")

#extract values for assertions/validations.
#_part1_check1=$(echo -e "${_part1}" | grep "wehadababyitsaboy!" || echo "not found")
#_part1_check2=$(yq e ".hello.greeting1" "./deploy/target/render/render/test1.yml")

#if test consists of multiple parts, do what you need to do to setup the next part here.

#execute the next part by running shrendd as necessary
#_part2=$(./shrendd -init || echo "finished shrendd with errors...")

#extract values for assertions/validations.
#_part2_check1=$(echo -e "${_part2}" | grep "wehadababyitsaboy!" || echo "not found")
#_part2_check2=$(yq e ".hello.greeting1" "./deploy/target/render/render/test1.yml")

#repeat as necessary for each part/phase of the test.

#initialize test_results, set `test_results` to the name of the test folder. please leave the `:\n` in place.
export test_results="bootstrap_init:\n"
#validate/assert the checked values and use the `passed` or `failed` methods with a description of the validation/assertion.
if [[ "${_part1}" == "finished shrendd with errors..." ]]; then
  failed "part 1"
else
  passed "part 1"
fi
#if [[ "${_part1_check1}" == "not found" ]]; then
#  passed "part 1, check 1 asserts something"
#else
#  failed "part 1, check 1 asserts something"
#fi

#clean up after the test runs.
#you should probably just leave this as is unless you know what you are doing and have a good reason.
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh