#!/bin/bash
set -euo pipefail

function stageLeft {
  :
}

function targetDirs {
  export TEMPLATE_DIR="$(shrenddOrDefault "shrendd.$1.template.dir")"
  if [ -z "$TEMPLATE_DIR" ] || [ "$TEMPLATE_DIR" == "null" ]; then
    export TEMPLATE_DIR="$(shrenddOrDefault "shrendd.default.template.dir")"
  fi
}

function stubTarget {
  export target="$_stub"
  targetDirs "$_stub"
  cp -r "$SHRENDD_DIR/$_stub/toes/." "./$_module/$TEMPLATE_DIR/"
}

function stubConfig {
  _template_path="$(shrenddOrDefault "shrendd.config.definition")"
  echo "file: $_template_path"
  if [ -f "$_template_path" ]; then
    echo -e "${_YELLOW}${_template_path} already exists. If you really mean to stub it again, delete or rename the existing one and try again.${_CLEAR_TEXT_COLOR}"
  else
    echo -e "${_TEXT_INFO}templating config based on ${_GREEN}${_config}${_CLEAR_TEXT_COLOR}"
    cp "${_config}" "${_template_path}"
    sed -i "s/\"//g" "${_template_path}"
    #_toe=$(cat $SHRENDD_DIR/render/config/template.yml)
    _template=$(cat "$_template_path")
    _config_keys=$(keysFor "$_template")
    for _config_key in $_config_keys; do
      _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
      echo "key: $_config_key"
      yq -i ".$_config_key |= load_str(\"$SHRENDD_DIR/render/config/template.yml\")" "${_template_path}"
    done
  fi
}

export _DEPLOY_ERROR_DIR="$SHRENDD_DIR/errors"
if [ -d "$_DEPLOY_ERROR_DIR" ]; then
  rm -rf "$_DEPLOY_ERROR_DIR/*"
  shrenddLog "stub: reset error log directory: rm ${_DEPLOY_ERROR_DIR}/*"
else
  mkdir "$_DEPLOY_ERROR_DIR"
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