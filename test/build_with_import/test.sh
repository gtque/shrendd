#!/bin/bash
set -euo pipefail

source ../../build/test/start.sh
../../build/test/init_shrendd.sh
rm -rf ./deploy/target
rm -f ./deploy/config/config-template.yml
rm -rf ~/.shrendd/cache/shrendd-lib-test
if [ $# -gt 0 ]; then
  ./shrendd -b -verbose
  echo "debug test end!!!"
  exit 0
fi
echo "**************** build ********************"
_shrendd1=$(./shrendd -b -verbose || echo "build failed...")
echo -e "$_shrendd1"
export test_results="build_with_import:\n"
_something_cool="\$(getConfig \"something.cool\")"
_r1=$(echo "$_shrendd1" | grep "build failed..." || echo "passed")
_txt_import1=$(cat ./deploy/target/build/render/rabbit.txt | grep "butter, \$(getConfigOrEmpty \"lib.butter.milk2\")" || echo "failed")
_txt_import2=$(cat ./deploy/target/build/render/rabbit.txt | grep "melted butter (or \$(getConfig \"lib.butter.alternative2\")), milk, eggs, vanilla" || echo "failed")
_hole=$(cat ./deploy/target/build/render/hole.txt)
_rabbit=$(cat ./deploy/target/build/render/rabbit.txt)
sed -i -e "s/\"/_double_mcquote_/g" "./deploy/target/build/k8s/00_namespace.yml"
_no_imports=$(yq e ".metadata.labels.[\"kubernetes.io/metadata.name\"]" "./deploy/target/build/k8s/00_namespace.yml" | sed -e "s/_escaped_double_mcquote_/\\\\\"/g" | sed -e "s/_double_mcquote_/\"/g")
_configmap_namespace=$(yq e ".metadata.namespace" "./deploy/target/build/k8s/01_configmap.yml")
_configmap_version=$(yq e ".apiVersion" "./deploy/target/build/k8s/01_configmap.yml")
_configmap_script=$(cat ./deploy/target/build/k8s/01_configmap.yml | grep "echo \"\\\\\"\$(getConfig \\\\\"lib.script.message2\\\\\")\\\\\"\"" || echo "failed")
_expected_leafy_green=$(echo -e "hello:\n  greeting1: \$(getConfig \"TEST_HELLO\")\n  greeting2: \$(getConfig \"test.hello\")\n  greeting3: \$(getConfig \"test.hello\")\n  greeting4: \$(getConfig \"TEST_HELLO\")\n")
_lettuce=$(cat ./deploy/target/build/render/lettuce.txt)
_cabbage=$(cat ./deploy/target/build/render/cabbage.txt)
if [ "$_r1" == "passed" ]; then
  passed "build"
else
  failed "build"
fi
if [ "${_txt_import1}" == "failed" ]; then
  failed "first text import"
else
  passed "first text import"
fi
if [ "${_txt_import2}" == "failed" ]; then
  failed "second text import"
else
  passed "second text import"
fi
if [ "${_hole}" == "${_rabbit} ${_something_cool}${_rabbit}${_rabbit}${_something_cool}" ]; then
  passed "nested imports"
else
  failed "nested imports"
fi
if [ "${_no_imports}" == "\"\$(someScript \"\$(getConfig \"APP_TEST_NAMESPACE\")\")\"" ]; then
  passed "no imports: ${_no_imports}"
else
  failed "no imports: ${_no_imports} != \"\$(someScript \"\$(getConfig \"APP_TEST_NAMESPACE\")\")\""
fi
if [ "${_configmap_namespace}" == "\$(getConfig \"LIB_APP_TEST_NAMESPACE2\")" ]; then
  passed "yaml import 1: ${_configmap_namespace} == \$(getConfig \"LIB_APP_TEST_NAMESPACE2\")"
else
  failed "yaml import 1: ${_configmap_namespace} == \$(getConfig \"LIB_APP_TEST_NAMESPACE2\")"
fi
if [ "${_configmap_version}" == "v1" ]; then
  passed "yaml import 2: \"\${_configmap_version}\" == \"v1\""
else
  failed "yaml import 2: \"\${_configmap_version}\" == \"v1\""
fi
if [ "${_configmap_script}" != "failed" ]; then
  passed "yaml import 3"
else
  failed "yaml import 3"
fi
if [ "${_cabbage}" == "${_expected_leafy_green}" ]; then
  passed "self library with module reference with custom module shrendd.config"
else
  failed "self library with module reference with custom module shrendd.config: ${_cabbage}"
fi
if [ "${_lettuce}" == "${_expected_leafy_green}" ]; then
  passed "external library with module reference"
else
  failed "external library with module reference with custom module shrendd.config: ${_lettuce}"
fi
#../../build/test/cleanup_shrendd.sh
source ../../build/test/end.sh
