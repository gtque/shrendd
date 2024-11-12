#!/bin/bash
set -euo pipefail

function doEval {
  eval "echo -e \"$1\" > $2"
}

function actualRender {
  fname="$1"
  _template=$(cat $1)
  _rname=$(echo "$1" | sed -e "s/\.srd//g")
  _rname="$RENDER_DIR/$_rname"
  echo "doing the rendering"
  _eval=$(doEval "$_template" "$_rname")
  if [ $? -ne 0 ]; then
    echo "eval issue:_eval"
    #echo "error rendering $1" >> $RENDER_DIR/config_error.log
  fi
  echo "eval finished"
  echo -e "+++++++++++++++rendered $fname+++++++++++++++"
  cat "$_rname"
  echo -e "+++++++++++++++rendered $fname+++++++++++++++"
  if [ -f $RENDER_DIR/config_error.log ]; then
    echo "errors rendering:"
    cat $RENDER_DIR/config_error.log
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
  rm -rf $RENDER_DIR/render_error.log
  for fname in $config_files
  do
    rm -rf $RENDER_DIR/config_error.log
    echo -e "------------------------------------------------------\nrendering $fname"
    actualRender "$fname"
    if [ -f $RENDER_DIR/config_error.log ]; then
      echo "failed to render: $fname" >> $RENDER_DIR/render_error.log
    fi
    echo -e "end $fname\n------------------------------------------------------"
  done
  cd $_curdir
  if [ -f $RENDER_DIR/render_error.log ]; then
    echo "errors rendering templates:"
    cat $RENDER_DIR/render_error.log
    return 1
  else
    echo "finished rendering everything without errors"
  fi
}