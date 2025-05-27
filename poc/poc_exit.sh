#!/bin/bash

function r2 {
  echo "  r2"
  return 0
  echo "  r2 should not be here..."
}

function r1 {
  echo "r: $1"
  if [[ "$1" -lt 2 ]]; then
    r1 "$(($1 + 1))"
  else
    r2
  fi
  echo "end r: $1"
}

r1 "0"