#!/bin/bash
set -euo pipefail

export _merge_yaml=""
export _current_merge_yaml=""

function doEval {
  if [[ $# -gt 1 ]]; then
    shrenddLog "doEval($2):\n$1"
  else
    shrenddLog "doEval(in-line):\n$1"
  fi
  if [[ "$SKIP_RENDER" == false ]]; then
    if [ $# -gt 1 ]; then
      eval "echo -e \"$1\" > $2" 2>> $_DEPLOY_ERROR_DIR/config_error.log
    else
      eval "echo -e \"$1\"" 2>> $_DEPLOY_ERROR_DIR/config_error.log
    fi
  else
    _text=$(echo -e "$1" | sed -e "s/\${/_dollar_curly_/g" | sed -e "s/}/_close_curly_/g" | sed -e "s/\$(/_dollar_parenthesis_/g" | sed -e "s/)/_close_parenthesis_/g" | sed -e "s/\\$/_dollar_sign_/g")
    _text=$(echo -e "${_text}" | sed -e "s/_dollar_parenthesis_importShrendd \(\".*\"\)_close_parenthesis_/\$(importShrendd \1)/g")
    if [[ $# -gt 1 ]]; then
      shrenddLog "build only: doEval(${2}):\n${_text}"
    else
      shrenddLog "build only: doEval(in-line):\n${_text}"
    fi
    if [[ $# -gt 1 ]]; then
      eval "echo -e \"${_text}\" | sed -e \"s/_dollar_curly_/\\\${/g\" | sed -e \"s/_close_curly_/}/g\" | sed -e \"s/_dollar_parenthesis_/\\\$(/g\" | sed -e \"s/_close_parenthesis_/)/g\" | sed -e \"s/_dollar_sign_/\\$/g\" > $2" 2>> $_DEPLOY_ERROR_DIR/config_error.log
    else
      eval "echo -e \"${_text}\" | sed -e \"s/_dollar_curly_/\\\${/g\" | sed -e \"s/_close_curly_/}/g\" | sed -e \"s/_dollar_parenthesis_/\\\$(/g\" | sed -e \"s/_close_parenthesis_/)/g\" | sed -e \"s/_dollar_sign_/\\$/g\"" 2>> $_DEPLOY_ERROR_DIR/config_error.log
    fi
  fi
}

function mergeYaml {
#  yq ea '. as $item ireduce ({}; . * $item )' $_temp_file $1 > $1.tmp

#  "$(echo "$")"
  while IFS= read -r _temp_file; do
    echo "merging: $_temp_file -> $1"
    _merge_value="${_temp_file}:::"
    _target=$(echo "$_merge_value" | cut -d':' -f1)
    _place_holder_key=$(echo "$_merge_value" | cut -d':' -f2)
    _place_holder_value=$(yq e ".$_place_holder_key" $1)
#    echo "  target:$_target"
#    echo "  _place_holder_key:$_place_holder_key"
#    echo "  _place_holder_value:$_place_holder_value"
    if [ "$_place_holder_value" == "null" ]; then
      echo -e "${_TEXT_WARN}no place holder found ($_place_holder_key), adding one.${_CLEAR_TEXT_COLOR}"
      yq -i ".${_place_holder_key} = \"doh!\"" $1
    fi
    _og="$1"
    sed -i -e "s/\"/_double_mcquote_/g" $_og
    sed -i -e "s/\"/_double_mcquote_/g" $_target
#    yq ea '. as $item ireduce ({}; . * $item )' $_og $_target $_og
    yq ea '. as $item ireduce ({}; . * $item )' $_og $_target $_og > "$_og.tmp"
#    echo "source:"
#    cat "$_og"
#    echo "end source"
#    echo "target:"
#    cat "$_target"
#    echo "end target"
#    echo "current progress:"
#    cat "$_og.tmp"
#    echo "end current progress"
    shrenddLog "mergeYaml: rm ${_og}"
    rm -rf $_og
    cp $_og.tmp $_og
#    rm -rf $_target
    if [ -n "$_place_holder_key" ]; then
      yq -i "del(.${_place_holder_key})" $_og
    fi
  done <<< "$_merge_yaml"
  shrenddLog "mergeYaml: cleanup: rm ${_og}"
  rm -rf "$1.tmp"
  sed -i -e "s/_double_mcquote_/\"/g" $1
#  yq -i -P 'sort_keys(..)' $1
}

function actualRender {
#  export _merge_yaml="false"
  if [ -f "$_current_merge_yaml" ]; then #$RENDER_DIR/temp" ]; then
    shrenddLog "actualRender: rm ${_current_merge_yaml}"
    rm -rf "$_current_merge_yaml" #$RENDER_DIR/temp/merge_yaml"
  else
    if [ -d "$RENDER_DIR/temp" ]; then
      :
    else
      mkdir -p "$RENDER_DIR/temp"
    fi
  fi
  fname="$1"
  _template=$(configify "$fname")
  _rname=$(echo "$1" | sed -e "s/\.srd//g")
  _rname="$RENDER_DIR/$_rname"
  echo -e "doing the rendering:\n${_TEXT_INFO}$_template${_CLEAR_TEXT_COLOR} -> $_rname"
  _eval_merge_yaml="$_current_merge_yaml"
  export _current_merge_yaml="${_rname}.merge.yml"
  doEval "$_template" "$_rname"
#  if [ -z "$_eval_result" ] || [ "$_eval_result" == "" ]; then
#    echo "error rendering $1: $_eval_result" >> $_DEPLOY_ERROR_DIR/config_error.log
#  fi
  echo "eval finished"
  if [ -f "$_current_merge_yaml" ]; then #$RENDER_DIR/temp/merge_yaml
    echo "yaml imports found, attempting to merge yaml"
    cat "$_current_merge_yaml" #$RENDER_DIR/temp/merge_yaml"
    export _merge_yaml=$(cat "$_current_merge_yaml") #$RENDER_DIR/temp/merge_yaml")
    mergeYaml "$_rname"
  else
    echo "no yaml imports..."
  fi
  echoSensitive "$(cat $_rname)"
  shrenddLog "mergeYaml: clean up current merge list: rm ${_current_merge_yaml}"
  rm -rf ${_current_merge_yaml}
  export _current_merge_yaml="$_eval_merge_yaml"
  echo -e "${_TEXT_PASS}+++++++++++++++rendered $fname+++++++++++++++"
  echoSensitive "$(cat $_rname)"
  echo -e "+++++++++++++++rendered $fname+++++++++++++++${_CLEAR_TEXT_COLOR}"
  if [ -f $_DEPLOY_ERROR_DIR/config_error.log ]; then
    _render_errors=$(cat $_DEPLOY_ERROR_DIR/config_error.log)
    if [ "$_render_errors" == "" ]; then
      echo "no errors detected."
      shrenddLog "actualRender: cleanup config error logs: rm ${_DEPLOY_ERROR_DIR}/config_error.log"
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
        shrenddLog "doRender: reset config error logs: rm ${_DEPLOY_ERROR_DIR}/config_error.log"
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