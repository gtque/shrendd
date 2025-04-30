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

function stubTarget {
  export target=$_stub
  targetDirs $_stub
  cp -r $SHRENDD_WORKING_DIR/.shrendd/$_stub/toes/. ./$_module/$TEMPLATE_DIR/
}

function stubConfig {
  _template_path="$(shrenddOrDefault "shrendd.config.definition")"
  echo "file: $_template_path"
  if [ -f $_template_path ]; then
    echo -e "${_YELLOW}${_template_path} already exists. If you really mean to stub it again, delete or rename the existing one and try again.${_NC}"
  else
    echo -e "${_LIGHT_BLUE}templating config based on ${_GREEN}${_config}${_NC}"
    cp ${_config} ${_template_path}
    sed -i "s/\"//g" "${_template_path}"
    #_toe=$(cat $SHRENDD_WORKING_DIR/.shrendd/render/config/template.yml)
    _template=$(cat $_template_path)
    _config_keys=$(keysFor "$_template")
    for _config_key in $_config_keys; do
      echo "key: $_config_key"
      yq -i ".$_config_key |= load_str(\"$SHRENDD_WORKING_DIR/.shrendd/render/config/template.yml\")" ${_template_path}
    done
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

if [ "$_stub" == "config" ]; then
  stubConfig
else
  stubTarget
fi