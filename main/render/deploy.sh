#!/bin/bash
set -euo pipefail

export _merge_yaml=""

function doEval {
  eval "echo -e \"$1\" > $2" 2>> $_DEPLOY_ERROR_DIR/config_error.log
}

function configify {
  cat $1 | sed -e "s/\\\${\([^}]*\)}/\\\$(getConfig \"\1\")/g"
}

function mergeYaml {
  while IFS= read -r _temp_file; do
#    echo "merging: $_temp_file -> $1"
#    echo ">>>>>>>>>>>>>>>>>>>>>>>$_temp_file"
#    cat "$_temp_file"
#    echo -e "<<<<<<<<<<<<<<<<<<<<<<<$1"
#    cat "$1"
#    yq ". *= load(\"$_temp_file\")" $1
    yq ea '. as $item ireduce ({}; . * $item )' $_temp_file $1 > $1.tmp
    rm -rf $1
    cp $1.tmp $1
#    _merged=$(yq e '. as $item ireduce ({}; . * $item)' $_temp_file $1)
#    echo -e "$_merged" > $1
  done <<< "$_merge_yaml"
  rm -rf $1.tmp
#  yq -i -P 'sort_keys(..)' $1
}

function actualRender {
#  export _merge_yaml="false"
  rm -rf "$RENDER_DIR/temp/merge_yaml"
  fname="$1"
  _template=$(configify "$fname")
  _rname=$(echo "$1" | sed -e "s/\.srd//g")
  _rname="$RENDER_DIR/$_rname"
  echo -e "doing the rendering:\n${_TEXT_INFO}$_template${_CLEAR_TEXT_COLOR} -> $_rname"
  doEval "$_template" "$_rname"
#  if [ -z "$_eval_result" ] || [ "$_eval_result" == "" ]; then
#    echo "error rendering $1: $_eval_result" >> $_DEPLOY_ERROR_DIR/config_error.log
#  fi
  echo "eval finished"
  echoSensitive "$(cat $_rname)"
  if [ -f "$RENDER_DIR/temp/merge_yaml" ]; then
    echo "yaml imports found, attempting to merge yaml"
    cat "$RENDER_DIR/temp/merge_yaml"
    export _merge_yaml=$(cat "$RENDER_DIR/temp/merge_yaml")
    mergeYaml "$_rname"
  else
    echo "no imports..."
  fi
  echo -e "${_TEXT_PASS}+++++++++++++++rendered $fname+++++++++++++++"
  echoSensitive "$(cat $_rname)"
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
      if [ "$fname" != "*.srd" ]; then
        rm -rf $_DEPLOY_ERROR_DIR/config_error.log
        echo -e "------------------------------------------------------\nrendering $fname"
        actualRender "$fname"
        if [ -f $_DEPLOY_ERROR_DIR/config_error.log ]; then
          echo "failed to render: $TEMPLATE_DIR/$fname" >> $_DEPLOY_ERROR_DIR/render_error.log
          cat $_DEPLOY_ERROR_DIR/config_error.log | sed -e "s/^/  /g" >> $_DEPLOY_ERROR_DIR/render_error.log
        fi
        echo -e "end $fname\n------------------------------------------------------"
      fi
    done
    cd $_curdir
    if [ -f $_DEPLOY_ERROR_DIR/render_error.log ]; then
      echo -e "${_TEXT_ERROR}errors rendering templates${_CLEAR_TEXT_COLOR}"
    else
      echo -e "${_TEXT_INFO}finished rendering everything without errors${_CLEAR_TEXT_COLOR}"
    fi
  fi
}