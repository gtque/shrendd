#!/bin/bash
set -euo pipefail

export _merge_yaml=""
export _current_merge_yaml=""

function doEval {

  _sanitized="$(echo -e "$1" | sed '/\$(shrenddIfTrue .*/d')"
  if [[ $# -gt 1 ]]; then
    shrenddLog "doEval($2) pre-processing:\n$1"
  else
    shrenddLog "doEval(in-line) pre-processing:\n$1"
  fi
  if [[ "$SKIP_RENDER" == false ]]; then
    if [ $# -gt 1 ]; then
      eval "echo -e \"$_sanitized\" > \"$2\"" 2>> "$_DEPLOY_ERROR_DIR/config_error.log"
    else
      eval "echo -e \"$_sanitized\"" 2>> "$_DEPLOY_ERROR_DIR/config_error.log"
    fi
  else
    _text=$(echo -e "$_sanitized" | sed -e "s/\$(importShrendd \([-\"a-zA-Z0-9:/._> ]*\))/_dollar_parenthesis_importShrendd \1_importShrendd_close_curly/g" | sed -e "s/\${/_dollar_curly_/g" | sed -e "s/}/_close_curly_/g" | sed -e "s/\$(/_dollar_parenthesis_/g" | sed -e "s/)/_close_parenthesis_/g" | sed -e "s/\\$/_dollar_sign_/g")
    _text=$(echo -e "${_text}" | sed -e "s/\"/_double_shrendd_quotes/g" | sed -e "s/_dollar_parenthesis_importShrendd/\$(importShrendd/g" | sed -e "s/_importShrendd_close_curly/)/g" | sed -e "s/importShrendd _double_shrendd_quotes/importShrendd \"/g" | sed -e "s/_double_shrendd_quotes\( *\))/\"\1)/g")
#    _has_import="$(echo -e "${_text}" | grep "_dollar_parenthesis_importShrendd" || echo "false")"
#    while [[ "${_has_import}" != "false" ]]; do
#      _text=$(echo -e "${_text}" | sed -e "s/_dollar_parenthesis_importShrendd \(.*\)_close_parenthesis_/\$(importShrendd \1)/g" | sed -e "s/_close_parenthesis_\(.*\)_dollar_parenthesis_importShrendd/)\1\$(importShrendd/g")
#      _has_import="$(echo -e "${_text}" | grep "_dollar_parenthesis_importShrendd" || echo "false")"
##      if [[ "${_has_import}" != "false" ]]; then
##        echo -e "still has import:\n$_text"
###        exit 1
##      fi
#    done
    if [[ $# -gt 1 ]]; then
      shrenddLog "build only: doEval(${2}):\n${_text}"
    else
      shrenddLog "build only: doEval(in-line):\n${_text}"
    fi
    if [[ $# -gt 1 ]]; then
      shrenddLog "echo some sensitive values..."
      eval "echo -e \"${_text}\" | sed -e \"s/_double_shrendd_quotes/\\\"/g\" | sed -e \"s/_dollar_curly_/\\\${/g\" | sed -e \"s/_close_curly_/}/g\" | sed -e \"s/_dollar_parenthesis_/\\\$(/g\" | sed -e \"s/_close_parenthesis_/)/g\" | sed -e \"s/_dollar_sign_/\\$/g\" > \"$2\"" 2>> "$_DEPLOY_ERROR_DIR/config_error.log"
      shrenddLog "checking: $_DEPLOY_ERROR_DIR/config_error.log"
      if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
        shrenddLog "dumping error log..."
        _error=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
        if [[ -z "$_error" ]]; then
          shrenddLog "no errors building"
        else
          shrenddLog "echo -e \"${_text}\" | sed -e \"s/_double_shrendd_quotes/\\\"/g\" | sed -e \"s/_dollar_curly_/\\\${/g\" | sed -e \"s/_close_curly_/}/g\" | sed -e \"s/_dollar_parenthesis_/\\\$(/g\" | sed -e \"s/_close_parenthesis_/)/g\" | sed -e \"s/_dollar_sign_/\\$/g\" > \"$2\""
          shrenddLog "error building (${2}):\n $(cat "$_DEPLOY_ERROR_DIR/config_error.log")\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
          exit 1
        fi
      fi
    else
      eval "echo -e \"${_text}\" | sed -e \"s/_double_shrendd_quotes/\\\"/g\" | sed -e \"s/_dollar_curly_/\\\${/g\" | sed -e \"s/_close_curly_/}/g\" | sed -e \"s/_dollar_parenthesis_/\\\$(/g\" | sed -e \"s/_close_parenthesis_/)/g\" | sed -e \"s/_dollar_sign_/\\$/g\"" 2>> "$_DEPLOY_ERROR_DIR/config_error.log"
      if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
        _error=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
        if [[ -z "$_error" ]]; then
          shrenddLog "no errors building"
        else
          shrenddLog "error building (in-line):\n $(cat "$_DEPLOY_ERROR_DIR/config_error.log")\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
        fi
      fi
    fi
  fi
}

function mergeYaml {
#  yq ea '. as $item ireduce ({}; . * $item )' $_temp_file $1 > $1.tmp
  shrenddLog "mergeYaml: yaml merge starting------------------->"
  if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
    _error=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
    if [[ -z "$_error" ]]; then
      shrenddLog "mergeYaml: no errors before merging"
    else
      shrenddLog "mergeYaml: error before merging: $1 \n${_error}"
    fi
  fi
#  "$(echo "$")"
  while IFS= read -r _temp_file; do
    _merge_value="${_temp_file}:::"
    _target=$(echo "$_merge_value" | cut -d':' -f1)
    shrenddLog "mergeYaml: merging: $_target -> $1"
    shrenddLog "mergeYaml: \n$(cat "$_target" | sed 's/^/\t/')"
    _og="$1"
    sed -i -e "s/\\\\\"/_escaped_double_mcquote_/g" "$_og"
    sed -i -e "s/\"/\\\\\"/g" "$_og"
    sed -i -e "s/\\\\\"/\"/" "$_og"
    sed -i -e "s/\\\\\"$/\"/" "$_og"
    sed -i -e "s/\\\\\"/_escaped_double_mcquote_/g" "$_og"
    sed -i -e "s/\"/_double_mcquote_/g" "$_og"
#    sed -i -e "s/\"\$(getConfig\([^)]*\))\"/\$(getConfig ---\1---)/g" "$_og"
    shrenddLog "mergeYaml: \nog file:\n$(cat "$_og" | sed 's/^/\t/')"
    _place_holder_key=$(echo "$_merge_value" | cut -d':' -f2)
    _place_holder_value=$(yq e ".$_place_holder_key" "$_og")
    _in_error="false"
    if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
      _error=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
      if [[ -z "$_error" ]]; then
        shrenddLog "mergeYaml: no errors looking up place holder handling"
      else
        _in_error="true"
        shrenddLog "mergeYaml: error looking place holder handling: $_og \n${_error}"
      fi
    fi
    if [ "$_in_error" == "true" ]; then
      shrenddLog "mergeYaml: aborting merge, error detected"
      break
    fi
    shrenddLog "mergeYaml: merging: place holder key: $_place_holder_key"
#    echo "  target:$_target"
#    echo "  _place_holder_key:$_place_holder_key"
#    echo "  _place_holder_value:$_place_holder_value"
    if [ -z "$_place_holder_key" ]; then
      shrenddLog "mergeYaml: no place holder specified"
    else
      shrenddLog "mergeYaml: place holder found, processing..."
      if [ "$_place_holder_value" == "null" ]; then
        shrenddLog "mergeYaml: ${_TEXT_WARN}no place holder found ($_place_holder_key), adding one.${_CLEAR_TEXT_COLOR}"
        yq -i ".${_place_holder_key} = \"doh!\"" "$_og"
      fi
    fi
    shrenddLog "mergeYaml: place holders handled"
    if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
      _error=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
      if [[ -z "$_error" ]]; then
        shrenddLog "mergeYaml: no errors after place holder handling"
      else
        shrenddLog "mergeYaml: error after place holder handling: $_og \n${_error}"
      fi
    fi
    sed -i -e "s/\\\\\"/_escaped_double_mcquote_/g" "$_target"
    sed -i -e "s/\"/\\\\\"/g" "$_target"
    sed -i -e "s/\\\\\"/\"/" "$_target"
    sed -i -e "s/\\\\\"$/\"/" "$_target"
    sed -i -e "s/\\\\\"/_escaped_double_mcquote_/g" "$_target"
    sed -i -e "s/\"/_double_mcquote_/g" "$_target"
    shrenddLog "mergeYaml: \ntarget file:\n$(cat "$_target" | sed 's/^/\t/')"
#    yq ea '. as $item ireduce ({}; . * $item )' "$_og" "$_target" "$_og"
    yq ea '. as $item ireduce ({}; . * $item )' "$_og" "$_target" "$_og" > "$_og.tmp"
    if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
      _error=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
      if [[ -z "$_error" ]]; then
        shrenddLog "mergeYaml: no errors after og to temp"
      else
        shrenddLog "mergeYaml: error after og to temp: $_og \n${_error}"
      fi
    fi
    shrenddLog "mergeYaml: \nog tmp:\n$(cat "${_og}.tmp" | sed 's/^/\t/')"
#    echo "source:"
#    cat "$_og"
#    echo "end source"
#    echo "target:"
#    cat "$_target"
#    echo "end target"
#    echo "current progress:"
#    cat "$_og.tmp"
#    echo "end current progress"
    if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
      _error=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
      if [[ -z "$_error" ]]; then
        shrenddLog "mergeYaml: no errors merging"
      else
        shrenddLog "mergeYaml: error merging: \n$_target -> $1 \n$(cat "$_og")\n${_error}"
      fi
    fi
    shrenddLog "mergeYaml: \nmergeYaml: rm ${_og}"
    rm -rf "$_og"
    cp "$_og.tmp" "$_og"
#    rm -rf $_target
    if [ -n "$_place_holder_key" ]; then
      shrenddLog "mergeYaml: attempting to delete place holder from og"
      yq -i "del(.${_place_holder_key})" "$_og"
      shrenddLog "mergeYaml: deleted place holder from og"
    fi
  done <<< "$_merge_yaml"
  shrenddLog "mergeYaml: cleanup: rm ${_og}"
  rm -rf "$1.tmp"
  sed -i -e "s/_escaped_double_mcquote_/\\\\\"/g" "$1"
  sed -i -e "s/_double_mcquote_/\"/g" "$1"
  shrenddLog "mergeYaml: yaml merge finished<-------------------"
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
  shrenddEcho "doing the rendering:\n${_TEXT_INFO}$_template${_CLEAR_TEXT_COLOR} -> $_rname"
  _eval_merge_yaml="$_current_merge_yaml"
  export _current_merge_yaml="${_rname}.merge.yml"
  doEval "$_template" "$_rname"
#  if [ -z "$_eval_result" ] || [ "$_eval_result" == "" ]; then
#    echo "error rendering $1: $_eval_result" >> "$_DEPLOY_ERROR_DIR/config_error.log"
#  fi
  shrenddEcho "eval finished"
  if [ -f "$_current_merge_yaml" ]; then #$RENDER_DIR/temp/merge_yaml
    shrenddEcho "yaml imports found, attempting to merge yaml"
    shrenddEcho "$(cat "$_current_merge_yaml")" #$RENDER_DIR/temp/merge_yaml"
    export _merge_yaml=$(cat "$_current_merge_yaml") #$RENDER_DIR/temp/merge_yaml")
    set +e
    mergeYaml "$_rname" 2>> "$_DEPLOY_ERROR_DIR/config_error.log"
    set -e
    if [[ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]]; then
      _error=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
      if [[ -z "$_error" ]]; then
        shrenddLog "mergeYaml: no errors after merging yaml"
      else
        shrenddLog "mergeYaml: error after merging yaml: $_rname \n${_error}"
      fi
    fi
  else
    shrenddEcho "no yaml imports..."
  fi
  echoSensitive "$(cat "$_rname")"
  shrenddLog "mergeYaml: clean up current merge list: rm ${_current_merge_yaml}"
  rm -rf "${_current_merge_yaml}"
  export _current_merge_yaml="$_eval_merge_yaml"
  shrenddEcho "${_TEXT_PASS}+++++++++++++++rendered $fname+++++++++++++++"
  echoSensitive "$(cat "$_rname")"
  shrenddEcho "+++++++++++++++rendered $fname+++++++++++++++${_CLEAR_TEXT_COLOR}"
  if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
    _render_errors=$(cat "$_DEPLOY_ERROR_DIR/config_error.log")
    if [ "$_render_errors" == "" ]; then
      shrenddEcho "no errors detected."
      shrenddLog "actualRender: cleanup config error logs: rm ${_DEPLOY_ERROR_DIR}/config_error.log"
      rm "$_DEPLOY_ERROR_DIR/config_error.log"
    else
      shrenddEcho "errors rendering:"
      shrenddEcho "$(cat "$_DEPLOY_ERROR_DIR/config_error.log")"
    fi
  else
    shrenddEcho "finished rendering without errors"
  fi
}

function doRender {
  if [ -d "$1" ]; then
    _curdir=$(pwd)
    shrenddEcho "running bash templating..."
    cd "$1"
    config_files="*.srd"
    shrenddEcho "files should be in: $config_files"
    export _RENDER_ERRORS=""
    for fname in $config_files
    do
      if [ "$fname" != "*.srd" ]; then
        _ifTrue=$(grep -m 1 "^\$(shrenddIfTrue" $fname || echo "true")
        if [[ "$_ifTrue" != "true" ]]; then
          _ifTrue=$(echo "$_ifTrue" | sed -e "s/\n*$//" | sed -e "s/\r*$//")
          _ifTrue="$(eval "echo \"$_ifTrue\"")"
        else
          _ifTrueResult="true"
        fi
        if [[ "$_ifTrue" == "true" ]]; then
          shrenddLog "doRender: reset config error logs: rm ${_DEPLOY_ERROR_DIR}/config_error.log"
          rm -rf "$_DEPLOY_ERROR_DIR/config_error.log"
          shrenddEcho "------------------------------------------------------\nrendering $fname"
          actualRender "$fname"
          if [ -f "$_DEPLOY_ERROR_DIR/config_error.log" ]; then
            shrenddEcho "failed to render: $TEMPLATE_DIR/$fname" >> "$_DEPLOY_ERROR_DIR/render_error.log"
            shrenddEcho "$(cat "$_DEPLOY_ERROR_DIR/config_error.log")" | sed -e "s/^/  /g" >> "$_DEPLOY_ERROR_DIR/render_error.log"
          fi
          shrenddEcho "end $fname\n------------------------------------------------------"
        else
          shrenddEcho "------------------------------------------------------\nrendering $fname"
          shrenddEcho "skipping $fname due to condition not met: $_ifTrue"
          shrenddEcho "end $fname\n------------------------------------------------------"
        fi
      fi
    done
    cd "$_curdir"
    if [ -f "$_DEPLOY_ERROR_DIR/render_error.log" ]; then
      shrenddEcho "${_TEXT_ERROR}errors rendering templates${_CLEAR_TEXT_COLOR}"
    else
      shrenddEcho "${_TEXT_INFO}finished rendering everything without errors${_CLEAR_TEXT_COLOR}"
    fi
  fi
}

function shrendd_testBuild {
  echo "this is a test, nothing \${TEST_B} to see here: $(getConfig test.a)"
}