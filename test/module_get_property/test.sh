#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./folder/deploy/test/generated
rm -rf ./folder/deploy/k8s/generated
echo "------------------------------------------------------"
echo "initializing shrendd for test"
./shrendd -init
echo "------------------------------------------------------"
echo "running shrendd with get-property"
echo "------------------------------------------------------"
no_module="$(./shrendd --get-property "shrendd.test.property" -offline)"
folder_module="$(./shrendd --get-property "shrendd.test.property" --module folder -offline)"
echo "------------------------------------------------------"

export test_results="module_get_property:\n"

if [[ "$no_module" == "hello, world!" ]]; then
  passed "property without module specified"
else
  failed "property without module specified"
fi
if [[ "$folder_module" == "howdy, partner!" ]]; then
  passed "property with module specified"
else
  failed "property with module specified"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh