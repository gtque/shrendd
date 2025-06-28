#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -f ./shrendd.yml
_file_deleted="true"
if [[ -f "./shrendd.yml" ]]; then
  _file_deleted="false"
fi
./shrendd -init
export _file_created="false"
if [[ -f "./shrendd.yml" ]]; then
  _file_created="true"
fi
export test_results="shrendd_yaml_stub:\n"
if [[ "$_file_deleted" == "true" ]]; then
  passed "file deleted during init"
else
  failed "file deleted during init"
fi
if [[ "$_file_created" == "true" ]]; then
  passed "file created during shrendd"
else
  failed "file created during shrendd"
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh