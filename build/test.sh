#!/bin/bash
echo "hold my beer - drunk cousin at the wedding"
#export _TESTS="upshrendd_downgrade"
export _TESTS="version_latest_default_local version_latest_default version_latest_specified version_specified"
export _TESTS="$_TESTS render_no_template render_only_template"
export _TESTS="$_TESTS upshrendd_clone upshrendd_downgrade upshrendd_upgrade"
export _TESTS="$_TESTS shrendd_yaml_override"
export _TESTS="$_TESTS module_share module_custom_render module_unwind module_override_properties"
#export _TESTS="single_level_default"

cd test
export _FULL_TEST_RESULTS=""
export test_results=""
for test in $_TESTS; do
  echo -e "\n*********************running: $test*********************\n"
  cd $test
  test_results=$(./test.sh 2>&1 || echo "end of shrendd tests\n------------------------------------------\n$test failed\n------------------------------------------")
  echo -e "$test_results"
  test_results=$(echo "$test_results" | sed -z "s/start of shrendd tests.*end of shrendd tests//g" )
  export _FULL_TEST_RESULTS="$_FULL_TEST_RESULTS$test_results"
  cd ..
  echo -e "\n*********************finished: $test*********************\n"
done
echo -e "processing results:$_FULL_TEST_RESULTS"
passed=$(echo -e "$_FULL_TEST_RESULTS" | grep -c "passed")
#echo "string to search in" | grep "pattern" > /dev/null 2>&1 || echo "string if not found"
failed=$(echo -e "$_FULL_TEST_RESULTS" | grep -c "failed" > /dev/null 2>&1 || echo "0" )
if [ -z "$failed" ]; then
  failed=$(echo -e "$_FULL_TEST_RESULTS" | grep -c "failed")
fi
total=$((passed + failed))
echo -e "test summary:\n  total: $total passed: $passed failed: $failed"