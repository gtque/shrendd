#!/bin/bash
set -euo pipefail

function test_k8s_test1 {
  :
}

function test_k8s_test3 {
  _test3=$(getConfigOrEmpty "does.not.exist.test3")
  if [ -z "${_test3}" ]; then
    :
  else
    echo -e "$_test3 just some garbage to bork the yaml"
  fi
}

function test_k8s_test4 {
  _test4=$(getConfigOrEmpty "app.test.test4")
    if [ -z "$_test4" ]; then
      echo -e "just some garbage to bork the yaml"
    else
      echo -e "test4.message: \"passed\"\n  test4b.message: \"true\"\n"
    fi
}

function test_k8s_test5 {
  _test5="test5.status: \"true\"
  test5b.status: \"false\""
  echo -e "$_test5"
}