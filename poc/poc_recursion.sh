#!/bin/bash

function r1 {
  echo "r: $1"
  if [[ "$1" -lt 2 ]]; then
    r1 "$(($1 + 1))"
  else
    echo "  the end has been reached."
  fi
  echo "end r: $1"
}

r1 "0"