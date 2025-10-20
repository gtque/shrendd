#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
set +e
_valid=$(./shrendd -S -verbose)
set -e
echo -e "$_valid"
export test_results="config_template:\n"
_grill=$(echo -e "$_valid" | grep -F "\"bbq.grill\" has a value of \"*****\" which is not in the allowed list: *****" || echo "not found")
_grill2=$(echo -e "$_valid" | grep "exported BBQ_GRILL2" || echo "not found")
_smoker=$(echo -e "$_valid" | grep "exported BBQ_SMOKER" || echo "not found")
_smoker2=$(echo -e "$_valid" | grep -F "\"bbq.smoker2\" has a value of \"mesquite0\" which is not in the allowed list: ^([a-zA-Z]+)$" || echo "not found")
_grill2_sensitive=$(echo -e "$_valid" | grep "grill off" || echo "not found")
_grill_sensitive=$(echo -e "$_valid" | grep -F "^(|grill on|grill off)$" || echo "not found")
_smoker2_sensitive=$(echo -e "$_valid" | grep -F "^([a-zA-Z]+)$" || echo "not found")
if [[ "$_grill" == "not found" ]]; then
  failed "bbq.grill not allowed"
else
  passed "bbq.grill not allowed"
fi
if [[ "$_grill2" == "not found" ]]; then
  failed "bbq.grill2 sensitive match allowed"
else
  passed "bbq.grill2 sensitive match allowed"
fi
if [[ "$_smoker" == "not found" ]]; then
  failed "bbq.smoker matched allow"
else
  passed "bbq.smoker matched allow"
fi
if [[ "$_smoker2" == "not found" ]]; then
  failed "bbq.smoker2 mismatched and not allowed"
else
  passed "bbq.smoker2 mismatched and not allowed"
fi
if [[ "$_smoker2_sensitive" != "not found" ]]; then
  passed "bbq.smoker2 allowed unmasked"
else
  failed "bbq.smoker2 allowed unmasked"
fi
if [[ "$_grill2_sensitive" == "not found" ]]; then
  passed "bbq.grill2 allowed masked"
else
  failed "bbq.grill2 allowed masked"
fi
if [[ "$_grill_sensitive" == "not found" ]]; then
  passed "bbq.grill value masked"
else
  failed "bbq.grill value masked"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh