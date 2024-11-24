#!/bin/bash
set -euo pipefail

function doEval {
  eval "echo -e \"$1\" > $2" 2>> $_DEPLOY_ERROR_DIR/config_error.log
}

function actualRender {
  fname="$1"
  _template=$(cat $1 | sed -e "s/\\\${\([^}]*\)}/\\\$(getConfig \"\1\")/g")
  _rname=$(echo "$1" | sed -e "s/\.srd//g")
  _rname="$RENDER_DIR/$_rname"
  echo "doing the rendering"
  doEval "$_template" "$_rname"
#  if [ -z "$_eval_result" ] || [ "$_eval_result" == "" ]; then
#    echo "error rendering $1: $_eval_result" >> $_DEPLOY_ERROR_DIR/config_error.log
#  fi
  echo "eval finished"
  echo -e "+++++++++++++++rendered $fname+++++++++++++++"
  cat "$_rname"
  echo -e "+++++++++++++++rendered $fname+++++++++++++++"
  if [ -f $_DEPLOY_ERROR_DIR/config_error.log ]; then
    _render_errors=$(cat $_DEPLOY_ERROR_DIR/config_error.log)
    if [ "$_render_errors" == "" ]; then
      echo "no errors detected."
      rm $_DEPLOY_ERROR_DIR/config_error.log
    else
      echo "errors rendering:"
      cat $_DEPLOY_ERROR_DIR/config_error.log
    fi
  else
    echo "finished rendering without errors"
  fi
}

function doRender {
  _curdir=$(pwd)
  echo "running bash templating..."
  cd $1
  config_files="*.srd"
  echo "files should be in: $config_files"
  export _RENDER_ERRORS=""
  for fname in $config_files
  do
    rm -rf $_DEPLOY_ERROR_DIR/config_error.log
    echo -e "------------------------------------------------------\nrendering $fname"
    actualRender "$fname"
    if [ -f $_DEPLOY_ERROR_DIR/config_error.log ]; then
      echo "failed to render: $TEMPLATE_DIR/$fname" >> $_DEPLOY_ERROR_DIR/render_error.log
      cat $_DEPLOY_ERROR_DIR/config_error.log | sed -e "s/^/  /g" >> $_DEPLOY_ERROR_DIR/render_error.log
    fi
    echo -e "end $fname\n------------------------------------------------------"
  done
  cd $_curdir
  if [ -f $_DEPLOY_ERROR_DIR/render_error.log ]; then
    echo "errors rendering templates"
  else
    echo "finished rendering everything without errors"
  fi
}