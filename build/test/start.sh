#!/bin/bash
echo "start of shrendd tests"
export _TEST_ERROR='\033[0;31m'
export _TEST_PASS='\033[1;34m'
export _TEST_WARN='\033[0;33m'
export _CLEAR_TEXT_COLOR='\033[0m' # No Color
export test_results="remember to export this at the start of your test with a test specific message, test folder name works well:\n"

function failed {
  echo -e "${_TEST_ERROR}$1 -> failed${_CLEAR_TEXT_COLOR}\n"
  export test_results="$test_results\t${_TEST_ERROR}$1 -> failed${_CLEAR_TEXT_COLOR}\n"
}

function passed {
  echo -e "$1 -> passed\n"
  export test_results="$test_results\t$1 -> passed\n"
}