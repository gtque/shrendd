#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
rm -f ./config/config-template.yml
rm -rf ~/.shrendd/cache/shrendd-lib-test
rm -f ./shrendd.yml
cp ./test-init/shrendd_1.yml ./shrendd.yml
if [ $# -gt 0 ]; then
  ./shrendd --build -verbose
  echo "debug test end!!!"
  exit 0
fi
echo "**************** Phase 1 ********************"
_shrendd1=$(./shrendd -extract || echo "phase 1 failed...")
echo -e "$_shrendd1"
echo "**************** Phase 2 ********************"
./shrendd -r --config test_1.yml
_shrendd2=$(./shrendd -r -S --config test_1.yml || echo "phase 2 failed...")
echo -e "$_shrendd2"
echo "*************** Phase 3 *********************"
rm -f ./shrendd.yml
cp ./test-init/shrendd_2.yml ./shrendd.yml
_shrendd3=$(./shrendd -extract || echo "phase 3 failed...")
echo -e "$_shrendd3"
echo "*************** Phase 4 *********************"
_shrendd4=$(./shrendd -r -S --config test_2.yml || echo "phase 4 failed...")
echo -e "$_shrendd4"
export test_results="template_remote_library:\n"
_r1=$(echo "$_shrendd1" | grep "phase 1 failed..." || echo "passed")
if [ "$_r1" == "passed" ]; then
  passed "phase 1"
else
  failed "phase 1"
fi
_r2=$(echo "$_shrendd2" | grep "phase 2 failed..." || echo "passed")
if [ "$_r2" == "passed" ]; then
  passed "phase 2"
else
  failed "phase 2"
fi
_r3=$(echo "$_shrendd3" | grep "phase 3 failed..." || echo "passed")
if [ "$_r3" == "passed" ]; then
  passed "phase 3"
else
  failed "phase 3"
fi
_r4=$(echo "$_shrendd4" | grep "phase 4 failed..." || echo "passed")
if [ "$_r4" == "passed" ]; then
  passed "phase 4"
else
  failed "phase 4"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
