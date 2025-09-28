#!/bin/bash
set -euo pipefail

function single_level_default_message {
  if [ "$1" -gt 0 ]; then
    echo "spaghetti"
  else
    echo "sauce"
  fi
}