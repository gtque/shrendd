#!/bin/bash
set -euo pipefail

function stageLeft {
  :
}

function targetDirs {
  export TEMPLATE_DIR=$(shrenddOrDefault "shrendd.targets[] | select(.name==\"$1\") | .template.dir")
  if [ -z "$TEMPLATE_DIR" ] || [ "$TEMPLATE_DIR" == "null" ]; then
    export TEMPLATE_DIR=$(shrenddOrDefault "shrendd.default.template.dir")
  fi
}

export _DEPLOY_ERROR_DIR="$SHRENDD_WORKING_DIR/.shrendd/errors"
if [ -d $_DEPLOY_ERROR_DIR ]; then
  rm -rf $_DEPLOY_ERROR_DIR/*
else
  mkdir $_DEPLOY_ERROR_DIR
fi

if [ "$_requested_help" == "true" ]; then
  exit 0
fi

export _MODULE_DIR="./$_module"
export target=$_stub
targetDirs $_stub
cp -r $SHRENDD_WORKING_DIR/.shrendd/$_stub/toes/. ./$_module/$TEMPLATE_DIR/