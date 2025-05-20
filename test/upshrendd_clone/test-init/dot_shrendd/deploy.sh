#!/bin/bash
set -euo pipefail

source $SHRENDD_WORKING_DIR/.shrendd/render/${deploy_action}.sh

function stageLeft {
  _check="_MODULE_DIR"
  if [ -z "${!_check+x}" ]; then
    :
  else
    cd $_MODULE_DIR
    #loop over all types and delete the renders
    for _target in $targets; do
      targetDirs $_target
      if [ -d "$RENDER_DIR" ]; then
        echo "deleting $RENDER_DIR"
        rm -rf $RENDER_DIR
      fi
    done
  fi
}

function targetDirs {
  export TEMPLATE_DIR=$(shrenddOrDefault "shrendd.targets[] | select(.name==\"$1\") | .template.dir")
  if [ -z "$TEMPLATE_DIR" ] || [ "$TEMPLATE_DIR" == "null" ]; then
    export TEMPLATE_DIR=$(shrenddOrDefault "shrendd.default.template.dir")
  fi
  export RENDER_DIR=$(shrenddOrDefault "shrendd.targets[] | select(.name==\"$1\") | .render.dir")
  if [ -z "$RENDER_DIR" ] || [ "$RENDER_DIR" == "null" ]; then
    export RENDER_DIR=$(shrenddOrDefault "shrendd.default.render.dir")
  fi
}

#first parameter should be deployment target/type, ie: k8s, tf, etc...
function checkRenderDirectory {
  printf "checking for render directory.\n"
  if [ -z "$RENDER_DIR" ] || [ "$RENDER_DIR" == "null" ]; then
    echo "creating a temporary render directory"
    export RENDER_DIR=$(mktemp -d)
  else
    if [ -d $RENDER_DIR ]; then
      echo "rendered folder already exists, clearing directory."
      rm -rf $RENDER_DIR
    fi
    mkdir $RENDER_DIR
  fi
}

#first parameter should be deployment target/type, ie: k8s, tf, etc...
function render {
  prePostAfter "$1" "beforerender"
  prePostRender "$1" "beforerender"
  if [ "$SKIP_TEMPLATE" == "false" ]; then
    echo "rendering templates"
    doRender $TEMPLATE_DIR
  else
    echo "skipping template rendering"
  fi
  prePostRender "$1" "afterrender"
  prePostAfter "$1" "afterrender"
}

function prePostAfter {
  if [ -f ./deploy/$1/$deploy_action/$2.sh ]; then
    echo "processing ./deploy/$1/$deploy_action/$2.sh"
    source ./deploy/$1/$deploy_action/$2.sh
  else
    echo "no ./deploy/$1/$deploy_action/$2.sh"
  fi
}

function prePostRender {
  if [ -f $SHRENDD_WORKING_DIR/.shrendd/$1/$deploy_action/$2.sh ]; then
    echo "processing $SHRENDD_WORKING_DIR/.shrendd/$1/$deploy_action/$2.sh"
    source $SHRENDD_WORKING_DIR/.shrendd/$1/$deploy_action/$2.sh
  else
    echo "no $SHRENDD_WORKING_DIR/.shrendd/$1/$deploy_action/$2.sh"
  fi
}

function doDeploy {
  prePostAfter "$1" "pre"
  if [ "$SKIP_STANDARD" == "false" ]; then
    echo "running standard setup."
    source $SHRENDD_WORKING_DIR/.shrendd/$1/${deploy_action}/deploy.sh
  else
    echo "skipping standard $1/$deploy_action"
  fi
  prePostAfter "$1" "post"
}

function initConfig {
  _config_keys=$(keysFor "$_SHRENDD_CONFIG")
  _provided_keys="$(keysFor "$_PROVIDED_CONFIG") "
  echo "configuring: $_config_keys"
  _initialized="true"
  for _config_key in $_config_keys; do
    _name=$(trueName $_config_key)
    _provided_keys=$(echo "$_provided_keys" | sed -e "s/$_config_key //g")
    _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_config_key" -)
    if [ "${_value}" == "null" ]; then
      echo "  $_config_key was null, checking if required or default present."
      _template_value=$(echo "$_SHRENDD_CONFIG" | yq e ".$_config_key" -)
      _value_required=$(echo "$_template_value" | yq e ".required" -)
      if [ "${_value_required}" == "true" ]; then
        echo "  $_config_key is required but was not provided."
        echo "$_config_key is required but was not provided." >> $_DEPLOY_ERROR_DIR/render_error.log
        _initialized="false"
      else
        _value_default=$(echo "$_template_value" | yq e ".default" -)
        if [ "${_value_default}" == "null" ]; then
          echo "  $_config_key no default has been defined."
          if [ "${_strict}" == "true" ]; then
            echo "$_config_key is not required and was not provided and no default has been defined." >> $_DEPLOY_ERROR_DIR/render_error.log
            _initialized="false"
          else
            echo "$_config_key is not required and was not provided and no default has been defined." >> $_DEPLOY_ERROR_DIR/render_warning.log
          fi
        else
          echo "  $_config_key using default value"
          _value="${_value_default}"
        fi
      fi
    fi
    if [ "${_value}" == "null" ]; then
      echo "not initializing> $_config_key"
    else
      echo "initializing> $_config_key: $_name: $_value"
      export $_name="$_value"
    fi
  done
  for _config_key in $_provided_keys; do
    echo "  $_config_key not defined in the template."
    if [ "${_strict}" == "true" ]; then
      echo "$_config_key not defined in the template." >> $_DEPLOY_ERROR_DIR/render_error.log
      _initialized="false"
    else
      _name=$(trueName $_config_key)
      _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_config_key" -)
      echo "initializing> $_config_key: $_name: $_value"
      export $_name="$_value"
      echo "$_config_key not defined in the template." >> $_DEPLOY_ERROR_DIR/render_warning.log
    fi
  done
  if [ "$_initialized" == "false" ]; then
    echo "something was missing in the template, please update the template and try again."
    exit 1
  fi
}

function getSecret {
  _secret=$(getConfig "$1")
  if [ $? -ne 0 ]; then
    echo -e "${_secret}"
  else
    _secret=$(echo -e "$_secret" | base64)
    echo -e "$_secret"
  fi
}

function getConfig {
  _name=$(trueName "$1")
  if [ -z "${!_name+x}" ]; then
    echo "error getting config for $1" >> $_DEPLOY_ERROR_DIR/config_error.log
    echo -e "\${${1}}"
    return 1
  else
      if [ -z "$_value" ] || [ "$_value" == "" ]; then
        echo ""
      else
        _value=$(eval "echo -e \"${!_name}\"")
        echo -e "$_value"
      fi
  fi
}

function getAsIs {
  _name=$(trueName "$1")
  if [ -z "${!_name+x}" ]; then
    echo "error getting config for $1" >> $_DEPLOY_ERROR_DIR/config_error.log
    echo -e "\${${1}}"
    return 1
  else
      if [ -z "$_value" ] || [ "$_value" == "" ]; then
        echo ""
      else
        echo -e "${!_name}"
      fi
  fi
}

function getConfigOrEmptyD {
  _check=$(trueName "$1")
  echo "truename for config: $_check"
  if [ -z "${!_check+x}" ]; then
    echo " was empty"
  else
    echo " was not empty?"
    getConfig "$1"
  fi
}

function getConfigOrEmpty {
  _check=$(trueName "$1")
  if [ -z "${!_check+x}" ]; then
    :
  else
    getConfig "$1"
  fi
}

function toYaml {
  echo -e "$1" | yq e '. | to_yaml' -
}

function padding {
  num_spaces=$1
  if [ -z "$num_spaces" ]; then
    num_spaces="0"
  fi
  spaces=$(printf "%${num_spaces}s")
  echo "$spaces"
}

export _DEPLOY_ERROR_DIR="$SHRENDD_WORKING_DIR/.shrendd/errors"
if [ -d $_DEPLOY_ERROR_DIR ]; then
  rm -rf $_DEPLOY_ERROR_DIR/*
else
  mkdir $_DEPLOY_ERROR_DIR
fi

if [ "$_requested_help" == "true" ]; then
  if [ "$_is_debug" == true ]; then
    echo "config: $_config"
    echo "module: $_module"
  fi
  exit 0
fi

if [ "$_config" == "false" ]; then
  echo "--config must be specified, otherwise there is nothing to use for rendering."
  exit 1
fi

echo "config:"
cat $_config
echo ""

if [ -f $_config ]; then
  if [ "$(shrenddOrDefault "shrendd.config.validate")" == "true" ]; then
    export _SHRENDD_CONFIG=$(cat "$(shrenddOrDefault "shrendd.config.definition")")
  else
    export _SHRENDD_CONFIG=$(cat $_config)
  fi
  export _PROVIDED_CONFIG=$(cat $_config)
  echo "found $_config."
  initConfig
  echo "done initializing"
else
  echo "no $_config found, no custom parameters defined."
  export _SHRENDD_CONFIG=""
  exit 1
fi

echo "switching to module: $_module"
cd $_module

export _MODULE_DIR=$(pwd)

if [ -f ./deploy/$deploy_action/pre.sh ]; then
  echo "processing ./deploy/$deploy_action/pre.sh"
  source ./deploy/$deploy_action/pre.sh
else
  echo "no ./deploy/$deploy_action/pre.sh"
fi

echo "trying to load array of targets for: $_MODULE_DIR"
for _target in $targets; do
  export target="$_target"
  echo "deploying: $target"
  targetDirs "$target"
  checkRenderDirectory "$target"
  render "$target"
  if [ "$SKIP_DEPLOY" == "false" ]; then
    echo "deploying $target"
    doDeploy "$target"
  else
    echo "skipping deploy"
  fi
done

if [ -f ./deploy/$deploy_action/post.sh ]; then
  echo "processing ./deploy/$deploy_action/post.sh"
  source ./deploy/$deploy_action/post.sh
else
  echo "no ./deploy/$deploy_action/post.sh"
fi
