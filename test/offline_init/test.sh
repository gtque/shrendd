#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
source ../../build/release.sh

./shrendd -init -offline || echo "finished shrendd offline..."
export test_results="offline_init:\n"
if [[ -d "./.shrendd" ]]; then
  failed ".shrendd does not exist"
else
  passed ".shrendd does not exist"
fi

../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh