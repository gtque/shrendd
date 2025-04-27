#!/bin/bash
echo "initializing shrendd for tests"
if [ -d ./.shrendd ]; then
  rm -rf ./.shrendd
fi
rm -f ./shrendd
