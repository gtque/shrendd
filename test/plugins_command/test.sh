#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
mkdir ./.shrendd
rm -rf ./deploy/cheese
cp -r ./test-init/cheese ./.shrendd/cheese
if [ $# -gt 0 ]; then
  ./shrendd cheese:burger "only mustard" "only ketchup"
  echo "debug test end!!!"
  exit 0
fi
_valid=$(./shrendd cheese:burger "only mustard" "only ketchup")
echo -e "$_valid"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
_invalid=$(./shrendd pickles:burger "only mustard" "only ketchup" || echo "error caught")
echo -e "$_invalid"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
rm -rf ./.shrendd/errors
mkdir "./.shrendd/errors"
_specified=$(./shrendd shrendd:shrenddTemplateDir "render" "buckaroo")
rm -rf ./.shrendd/errors
mkdir "./.shrendd/errors"
echo -e "template dir for render:\n$_specified"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
_valid_module_render=$(echo -e "$_specified" | grep "plugins_command/buckaroo/deploy/render/templates" || echo "not found")
_specified2=$(./shrendd shrendd:shrenddTemplateDir "test")
echo -e "template dir for test:\n$_specified2"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
_valid_module_test=$(echo -e "$_specified2" | grep "plugins_command/deploy/test/templates" || echo "not found")
_invalid=$(echo -e "$_invalid" | grep "the plugin 'pickles' was not found or has no pickles file" || echo "not found")
echo "checking results"
export test_results="plugins_command:\n"
./shrendd cheese:cook
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
_predefined=$(echo -e "$_valid" | grep "no onions, no pickles:" || echo "not found")
_first=$(echo -e "$_valid" | grep "only mustard" || echo "not found")
_second=$(echo -e "$_valid" | grep "only ketchup" || echo "not found")
_cooked=$(yq e ".cheese.burger" "./deploy/cheese/cheese.yml")
if [[ "$_predefined" != "not found" ]]; then
  passed "call command"
else
  failed "call command"
fi
if [[ "$_first" != "not found" ]]; then
  passed "call command with one parameter"
else
  failed "call command with one parameter"
fi
if [[ "$_second" != "not found" ]]; then
  passed "call command with two parameters"
else
  failed "call command with two parameters"
fi
if [[ "$_invalid" != "not found" ]]; then
  passed "no plugin commands found"
else
  failed "no plugin commands found"
fi
if [ "$_cooked" == "flame broiled" ]; then
  passed "custom command write to file"
else
  failed "custom command write to file"
fi
if [ "$_valid_module_render" != "not found" ]; then
  passed "template dir, module specified"
else
  failed "template dir, module specified"
fi
if [ "$_valid_module_test" != "not found" ]; then
  passed "template dir, module default"
else
  failed "template dir, module default"
fi
../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh