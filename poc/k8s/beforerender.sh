#!/bin/bash
set -euo pipefail

function toYaml {
#  echo -e "$1" | yq e '. | to_yaml' -
  export _template_stub="$1"
  yq --null-input "$_template_stub"
}

function padding {
  num_spaces=$1
  if [ -z "$num_spaces" ]; then
    num_spaces="0"
  fi
  spaces=$(printf "%${num_spaces}s")
  echo "$spaces"
}

function k8s_to_yaml {
#  _test2=$(getConfigOrEmpty "$2")
  _pies=".test = \"
pies: |
  case: |
  - name: dutch apple
    crust: pastry
  - name: pecan
    crust: biscoff
  - name: chocolate cheesecake
    crust: oreo\""
  echo $_pies
  _test2=$(toYaml "$_pies")
  echo "$_test2"
  _padding=$(padding "2")
  if [ -n "${3+x}" ]; then
    if [ "$3" -gt 0 ]; then
      _padding=$(padding "$3")
    fi
  fi
  echo -e -n "\n$(echo "$_test2" | sed -e "s/^\(.*\)/$_padding\1/g")"
  echo ""
#  echo -e -n "$1\n$(echo "${_padding}$_test2")"
}

k8s_to_yaml