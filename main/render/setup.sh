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
  echo -e "doing the rendering:\n${_TEXT_INFO}$_template${_CLEAR_TEXT_COLOR} -> $_rname"
  doEval "$_template" "$_rname"
#  if [ -z "$_eval_result" ] || [ "$_eval_result" == "" ]; then
#    echo "error rendering $1: $_eval_result" >> $_DEPLOY_ERROR_DIR/config_error.log
#  fi
  echo "eval finished"
  echo -e "${_TEXT_PASS}+++++++++++++++rendered $fname+++++++++++++++"
  if [ -z "${_TUXEDO_MASK+x}" ]; then
    cat "$_rname"
  else
    replacement=$'\n' # Define replacement as a newline character
    _new_string=$(cat "$_rname")
    _new_string=$(echo "$_new_string" | sed ':a;N;$!ba;s/\r//g')
    #echo "processing newlines: $_new_string"
    _new_string=$(echo "$_new_string" | sed ':a;N;$!ba;s/\n/'$_NEW_LINE_PLACE_HOLDER'/g')
    #echo "curent string: $_new_string"
    #echo "processing sensitive values: $_TUXEDO_MASK"
    _new_string=$(echo "$_new_string" | sed "$_TUXEDO_MASK")
    #echo "replacing new lines: $_new_string"
    _new_string="${_new_string//$_NEW_LINE_PLACE_HOLDER/$replacement}"
    #echo "processed"
    echo -e "$_new_string"
  fi
  echo -e "+++++++++++++++rendered $fname+++++++++++++++${_CLEAR_TEXT_COLOR}"
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
  if [ -d "$1" ]; then
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
      echo -e "${_TEXT_ERROR}errors rendering templates${_CLEAR_TEXT_COLOR}"
    else
      echo -e "${_TEXT_INFO}finished rendering everything without errors${_CLEAR_TEXT_COLOR}"
    fi
  fi
}