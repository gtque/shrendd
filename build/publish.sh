#!/bin/bash
set -euo pipefail

echo "hold my beer - drunk cousin at the wedding"
export _NEW_FEATURES="N/A"
if [ $# -gt 0 ]; then
  export _NEW_FEATURES="$*"
fi

source ./build/release.sh
source ./build/build.sh
create_release $_VERSION $_BRANCH_NAME $_IS_PRE_RELEASE $_IS_LATEST "$_NEW_FEATURES"
upload_release_file ./build/target/$_VERSION/version.yml version.yml
upload_release_file ./build/target/$_VERSION/shrendd shrendd
upload_release_file ./build/target/$_VERSION/render.zip render.zip
upload_release_file ./build/target/$_VERSION/k8s.zip k8s.zip
upload_release_file ./build/target/$_VERSION/test.zip test.zip