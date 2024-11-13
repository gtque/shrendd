#!/bin/bash
set -euo pipefail

trap resetLocal EXIT

source $SHRENDD_WORKING_DIR/.shrendd/render/${deploy_action}.sh

function resetLocal {
  if [ $? -ne 0 ]; then
    echo "It seems there was an error during the process. Please review the logs for more information."
  fi
  if [ "$_is_debug" == true ]; then
    echo "running as debug, not deleting render directories"
  else
    echo "deleting $RENDER_DIR"
    rm -rf $RENDER_DIR
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
  echo "configuring: $_config_keys"
  for _config_key in $_config_keys; do
    _name=$(trueName $_config_key)
    _value=$(echo "$_SHRENDD_CONFIG" | yq e ".$_config_key" -)
    echo "initializing> $_config_key: $_name: $_value"
    eval "export $_name=\"$_value\""
  done
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
  _value=$(eval "echo -e \"${!_name}\"")
  if [ -z "$_value" ] || [ "$_value" == "" ]; then
    echo "error getting config for $1" >> $RENDER_DIR/config_error.log
    echo -e "\${${1}}"
    return 1
  else
    echo -e "$_value"
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
  export _SHRENDD_CONFIG=$(cat $_config)
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

echo "trying to load array of targets"
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
