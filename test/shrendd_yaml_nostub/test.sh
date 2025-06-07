#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
_file_deleted="false"
if [[ -f "./shrendd.yml" ]]; then
  _file_deleted="true"
fi
./shrendd -init
_not_stubbed=$(grep "git:" ./shrendd.yml || echo "true")
_file_created="false"
if [[ -f "./shrendd.yml" ]]; then
  _file_created="true"
fi
export test_results="shrendd_yaml_stub:\n"
if [[ "$_file_deleted" == "true" ]]; then
  passed "file not deleted during init"
else
  failed "file not deleted during init"
fi
if [[ "$_file_created" == "true" ]]; then
  passed "file exists"
else
  failed "file exists"
fi
if [[ "$_not_stubbed" == "true" ]]; then
  passed "file was not re-stubbed"
else
  failed "file was not re-stubbed"
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh