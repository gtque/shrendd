#!/bin/bash
set -euo pipefail

function k8s_to_yaml {
  _test2=$(getConfigOrEmpty "$2")
  _test2=$(toYaml "$_test2")
  _padding=$(padding "$(shrenddOrDefault "shrendd.k8s.yaml.padding")")
  if [ -n "${3+x}" ]; then
    if [ "$3" -gt 0 ]; then
      _padding=$(padding "$3")
    fi
  fi
  echo -e -n "$1\n$(echo "  $_test2" | sed -e "s/^/$_padding/g")"
}
