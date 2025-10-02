#!/bin/bash

if [ $# -gt 0 ]; then
  sleep $1 #sleepping to stagger tests a bit
fi

echo "hold my beer - drunk cousin at the wedding"
export _TESTS="version_latest_default_local version_latest_default version_latest_specified version_specified"
export _TESTS="$_TESTS render_render render_no_template render_only_template render_with_scripts"
export _TESTS="$_TESTS upshrendd_clone upshrendd_downgrade upshrendd_upgrade"
export _TESTS="$_TESTS shrendd_yaml_override shrendd_yaml_stub shrendd_yaml_nostub"
export _TESTS="$_TESTS module_share module_custom_render module_unwind module_override_properties module_get_property"
export _TESTS="$_TESTS template_extract template_spawn template_extract_cleanup template_spawn_cleanup template_extract_library template_remote_library"
export _TESTS="$_TESTS k8s_simple_deploy k8s_skip"
export _TESTS="$_TESTS plugins_get plugins_command plugins_execute"
export _TESTS="$_TESTS offline_init offline_library offline_plugin"
export _TESTS="$_TESTS build_with_import bootstrap_init"

#export _TESTS="single_level_default"
source ./build/test/start.sh
cd test
export _FULL_TEST_RESULTS=""
export test_results=""

start_time=$SECONDS

for test in $_TESTS; do
  echo -e "\n*********************running: $test*********************\n"
  cd $test
  test_start_time=$SECONDS
  test_results=$(./test.sh 2>&1 || echo "end of shrendd tests\n------------------------------------------\n${_TEST_ERROR}$test failed${_CLEAR_TEXT_COLOR}\n------------------------------------------")
  test_end_time=$SECONDS
  test_duration=$((test_end_time - test_start_time))
  test_durationM=$((test_duration / 60))
  test_durationS=$((test_duration % 60))
  test_execution_time="execution time: ${test_duration} seconds (${test_durationM} minutes and ${test_durationS} seconds)"
  echo -e "$test_results"
  _check=$(echo -e "$test_results" | grep "end of shrendd tests" || echo "not found")
  if [[ "$_check" == "not found" ]]; then
    test_results=$(echo "\n------------------------------------------\n${_TEST_ERROR}$test failed, not successfully ended, make sure 'source ../../build/test/end.sh' is at the end of the test and is reachable.${_CLEAR_TEXT_COLOR}\n------------------------------------------")
  else
    test_results=$(echo "$test_results" | sed -z "s/start of shrendd tests.*end of shrendd tests//g" )
    _check=$(echo -e "$test_results" | grep "passed" || echo "not found")
    if [[ "$_check" == "not found" ]]; then
      _check=$(echo -e "$test_results" | grep "failed" || echo "not found")
      if [[ "$_check" == "not found" ]]; then
        test_results=$(echo "\n------------------------------------------\n${_TEST_ERROR}$test failed, there does not appear to have been any validations performed, you can use 'passed \"some message\"' and 'failed \"some message\"' to indicate validation statuses${_CLEAR_TEXT_COLOR}\n------------------------------------------")
      fi
    fi
  fi
  export _FULL_TEST_RESULTS="$_FULL_TEST_RESULTS$test_results\n${test_execution_time}"
  cd ..
  echo -e "\n*********************finished: $test*********************\n"
done
end_time=$SECONDS
duration=$((end_time - start_time))
durationM=$((duration / 60))
durationS=$((duration % 60))
echo -e "processing results:$_FULL_TEST_RESULTS"
passed=$(echo -e "$_FULL_TEST_RESULTS" | grep -v "failed" | grep -c "passed")
#echo "string to search in" | grep "pattern" > /dev/null 2>&1 || echo "string if not found"
failed=$(echo -e "$_FULL_TEST_RESULTS" | grep -c "failed" > /dev/null 2>&1 || echo "0" )
if [ -z "$failed" ]; then
  failed=$(echo -e "$_FULL_TEST_RESULTS" | grep -c "failed")
fi
total=$((passed + failed))
echo -e "test summary:\n  total: $total passed: $passed failed: $failed\n  execution time: ${duration} seconds (${durationM} minutes and ${durationS} seconds) "
if [ "$failed" -gt 0 ]; then
  exit $failed
fi