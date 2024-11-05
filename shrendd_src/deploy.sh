#!/bin/bash
set -euo pipefail

trap resetLocal EXIT

function resetLocal {
  if [ "$_is_debug" == true ]; then
    echo "running as debug, not deleting render directories"
  else
    echo "deleting $RENDER_DIR"
    rm -rf $RENDER_DIR
  fi
}

function targetDirs {
  export TEMPLATE_DIR=$(getOrDefault ".shrendd.targets[] | select(.name==\"$1\") | .template.dir")
  if [ -z "$TEMPLATE_DIR" ] || [ "$TEMPLATE_DIR" == "null" ]; then
    export TEMPLATE_DIR=$(getOrDefault ".shrendd.default.template.dir")
  fi
  export RENDER_DIR=$(getOrDefault ".shrendd.targets[] | select(.name==\"$1\") | .render.dir")
  if [ -z "$RENDER_DIR" ] || [ "$RENDER_DIR" == "null" ]; then
    export RENDER_DIR=$(getOrDefault ".shrendd.default.render.dir")
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
    source $SHRENDD_WORKING_DIR/.shrendd/render/${deploy_action}.sh
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

echo "ansible config:"
cat $_config
echo ""

echo "switching to module: $_module"
cd $_module

export _MODULE_DIR=$(pwd)

if [ -f ./deploy/$deploy_action/pre.sh ]; then
  echo "processing ./deploy/$deploy_action/pre.sh"
  source ./deploy/$deploy_action/pre.sh
else
  echo "no ./deploy/$deploy_action/pre.sh"
fi

export target="k8s"
targetDirs "$target"
checkRenderDirectory "$target"
render "$target"
doDeploy "$target"

if [ -f ./deploy/$deploy_action/post.sh ]; then
  echo "processing ./deploy/$deploy_action/post.sh"
  source ./deploy/$deploy_action/post.sh
else
  echo "no ./deploy/$deploy_action/post.sh"
fi
