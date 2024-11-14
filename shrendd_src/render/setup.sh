#!/bin/bash
set -euo pipefail

function doEval {
  eval "echo -e \"$1\" > $2"
}

function actualRender {
  fname="$1"
  _template=$(cat $1 | sed -e "s/\\\${\([^}]*\)}/\\\$(getConfig \"\1\")/g")
  _rname=$(echo "$1" | sed -e "s/\.srd//g")
  _rname="$RENDER_DIR/$_rname"
  echo "doing the rendering"
  _eval=$(doEval "$_template" "$_rname")
  if [ $? -ne 0 ]; then
    echo "eval issue:_eval"
    #echo "error rendering $1" >> $_DEPLOY_ERROR_DIR/config_error.log
  fi
  echo "eval finished"
  echo -e "+++++++++++++++rendered $fname+++++++++++++++"
  cat "$_rname"
  echo -e "+++++++++++++++rendered $fname+++++++++++++++"
  if [ -f $_DEPLOY_ERROR_DIR/config_error.log ]; then
    echo "errors rendering:"
    cat $_DEPLOY_ERROR_DIR/config_error.log
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