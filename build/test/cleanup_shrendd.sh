#!/bin/bash
echo "cleaning up shrendd for tests"
if [ -d ./.shrendd ]; then
  rm -rf ./.shrendd
fi
rm -f ./shrendd
