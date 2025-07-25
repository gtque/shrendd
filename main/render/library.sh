#!/bin/bash

export _latest_libs=" "

function devDLib {
  _cdir=$(pwd)
  cd $2
  zip -rq "$1" "./" -x '*config/*' -x '*target*'
  cd $_cdir
}

function cloneLibrary {

  _library="$1"
  _version="$2"
  _bank="$3"
  _template="$4"
  if [[ "$_MODULE_DIR" == *"$_library" ]]; then
    _library="this"
  fi
  _xerox=$(shrenddOrDefault "shrendd.library.$_library.get.method")
  _xerox_settings=$(shrenddOrDefault "shrendd.library.$_library.get.parameters")
  _xerox_default="false"

  if [ -z "$_xerox" ] || [ "$_xerox" == "null" ]; then
    _xerox=$(shrenddOrDefault "shrendd.library.default.get.method")
  fi
  if [ -z "$_xerox_settings" ] || [ "$_xerox_settings" == "null" ]; then
    _xerox_settings=$(shrenddOrDefault "shrendd.library.default.get.parameters")
  fi
#  echo -e "settings:\n$_xerox\n$_xerox_settings\n$_library"
  if [ "$_xerox" == "devD" ]; then
    _xerox="devDLib"
  fi
  if [ "$_xerox" == "curl" ]; then
    _xerox="curlD"
  fi
  if [ "$_xerox" == "wget" ]; then
    _xerox="wgetD"
  fi

  if [[ "$_library" == "this" ]] || [[ "$_MODULE_DIR" == *"$_library" ]]; then
    _xerox="getThis"
  fi
  _destination="$_bank/$_library.zip"
  if [[ "$FORCE_SHRENDD_UPDATES" == "true" ]]; then
    if [[ "$_xerox" != "getThis" ]]; then
      shrenddLog "cloneLibrary: force updates: rm ${_bank}"
      rm -rf "$_bank"
    else
      shrenddLog "cloneLibrary: force updates: tried to rm ${_bank}, but this is local so I better leave it alone."
    fi
  fi
#  echo -e "xeroxing:\n$_bank\n$_destination"
  #should probably support a forced update of libraries
  if [ "$_version" == "latest" ] && [ "$_xerox" != "getThis" ]; then
    if [ "$_latest_libs" != *" $_library "* ]; then
      #really need to add a cache timeout for latest...
      shrenddLog "cloneLibrary: using latest, forcing update: rm ${_bank}"
      rm -rf "$_bank"
      export _latest_libs="${_latest_libs}${_library} "
    fi
  fi

#  if [ "$_xerox" == "getThis" ]
#    _xerox_settings="$_template"
#    _destination="$RENDER_DIR/temp/"
#  fi
  if [ "$_xerox" != "getThis" ]; then
    if [ -d $_bank ]; then
      :
    else
      mkdir -p "$_bank"
      #should support an offline mode here
      eval "$_xerox \"$_destination\" \"$(shrenddOrDefault "shrendd.library.$_library.get.src")\" \"$_xerox_settings\""
      unzip -aoq "$_bank/$_library.zip" -d "$_bank"
    fi
  fi
}

function importShrendd_auto {
  echo "autobots, rollout."
}

function importShrendd_txt {
  importShrendd_text "$1"
}

function importShrendd_text {
#  echo "texting: $1"
  _text=$(configify "$1")
#  echo -e "the text:$_text"
  shrenddLog "the text: \n${_text}"
  doEval "$_text"
}

function importShrendd_yml {
  importShrendd_yaml "$1"
}

function importShrendd_yaml {
#  echo "texting: $1"
  _text=$(configify "$1")
#  echo -e "the text:$_text"
  _temp_yaml="$RENDER_DIR/temp/$2/$3"
  _temp_yaml_dirs=$(echo "${_temp_yaml%/*}")
#  echo "#temp path: $_temp_yaml_dirs"
  mkdir -p "$_temp_yaml_dirs"
#  echo "#must merge: $_temp_yaml"
#  export _merge_yaml="${_merge_yaml}\n$_temp_yaml"
  if [ "$_merge_yaml" == "false" ]; then
    shrenddLog "importShrendd_yaml: start with clean merge yaml: rm ${_current_merge_yaml}"
    rm -rf "$_current_merge_yaml" #"$RENDER_DIR/temp/merge_yaml"
  fi
  export _merge_yaml="true"
  echo "$_temp_yaml" >> "$_current_merge_yaml" #"$RENDER_DIR/temp/merge_yaml"
  _eval_merge_yaml="$_current_merge_yaml"
  export _current_merge_yaml="${_temp_yaml}.merge.yml"
  shrenddLog "--------doEval start--------"
  shrenddLog "doEval $_text $_temp_yaml"
  shrenddLog "--------doEval end--------"
  doEval "$_text" "$_temp_yaml"
  if [ -f $_DEPLOY_ERROR_DIR/config_error.log ]; then
    _error=$(cat $_DEPLOY_ERROR_DIR/config_error.log)
    if [[ -z "$_error" ]]; then
      shrenddLog "importShrendd_yaml: no errors shrendd yaml import, so far"
    else
      shrenddLog "importShrendd_yaml: error shrendd yaml import before merging (${_temp_yaml}):\n $(cat ${_temp_yaml})\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    fi
  fi
  if [ -f "$_current_merge_yaml" ]; then #$RENDER_DIR/temp/merge_yaml
    _merge_results="yaml imports found, attempting to merge yaml"
    shrenddLog "yaml imports found, merging yaml..."
#    cat "$_current_merge_yaml" #$RENDER_DIR/temp/merge_yaml"
    export _merge_yaml=$(cat "$_current_merge_yaml") #$RENDER_DIR/temp/merge_yaml")
    _merge_results="$_merge_results\n$(mergeYaml "${_temp_yaml}" || echo "yaml merge failed")"
    if [ -f $_DEPLOY_ERROR_DIR/config_error.log ]; then
      _error=$(cat $_DEPLOY_ERROR_DIR/config_error.log)
      if [[ -z "$_error" ]]; then
        shrenddLog "importShrendd_yaml: no errors shrendd yaml import after merging"
      else
        shrenddLog "importShrendd_yaml: error shrendd yaml import after merging (${_temp_yaml}):\n $(cat ${_temp_yaml})\nerror: \n${_error}\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
      fi
    fi
    if [[ "$_merge_results" == *"yaml merge failed"* ]]; then
      shrenddLog "error merging yaml detected"
      echo "error merging yaml ${_temp_yaml}:" >> $_DEPLOY_ERROR_DIR/config_error.log
      cat "$_current_merge_yaml" >> $_DEPLOY_ERROR_DIR/config_error.log
    else
      shrenddLog "yaml merge successful"
      shrenddLog "${_temp_yaml}:\n$_merge_results"
    fi
    export _merge_yaml=""
  fi
  shrenddLog "importShrendd_yaml: end with clean merge yaml: rm ${_current_merge_yaml}"
  if [[ -f ${_current_merge_yaml} ]]; then
    shrenddLog "$(cat ${_current_merge_yaml})\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#    rm -rf ${_current_merge_yaml}
  else
    shrenddLog "no merge yaml, nothing to do."
  fi
  export _current_merge_yaml="$_eval_merge_yaml"
  shrenddLog "new _current_merge_yaml: ${_current_merge_yaml}"
  if [[ -f ${_current_merge_yaml} ]]; then
    shrenddLog "new current: \n $(cat ${_current_merge_yaml})\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    _foundit="$(cat ${_current_merge_yaml} | grep "/home/angeli217/code/dev/shrendd/test/build_with_import/deploy/target/build/k8s/temp/shrendd-lib-test/k8s/configmaps/script_configmap.yml.srd" || echo "not found")"
    if [[ "${_foundit}" != "not found" ]]; then
      shrenddLog "$(cat "/home/angeli217/code/dev/shrendd/test/build_with_import/deploy/target/build/k8s/temp/shrendd-lib-test/k8s/configmaps/script_configmap.yml.srd")\n:::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    else
      shrenddLog "not it..."
    fi
  else
    shrenddLog "no merge yaml for the new current"
  fi
  if [ -f $_DEPLOY_ERROR_DIR/config_error.log ]; then
    _error=$(cat $_DEPLOY_ERROR_DIR/config_error.log)
    if [[ -z "$_error" ]]; then
      shrenddLog "no errors building before returning from importShrendd_yaml"
    else
      shrenddLog "echo -e \"${_text}\" | sed -e \"s/_double_shrendd_quotes/\\\"/g\" | sed -e \"s/_dollar_curly_/\\\${/g\" | sed -e \"s/_close_curly_/}/g\" | sed -e \"s/_dollar_parenthesis_/\\\$(/g\" | sed -e \"s/_close_parenthesis_/)/g\" | sed -e \"s/_dollar_sign_/\\$/g\" > $2"
      shrenddLog "error building importShrendd_yaml (${2}):\n $(cat $_DEPLOY_ERROR_DIR/config_error.log)\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    fi
  fi
  shrenddLog "->returning from importShrendd_yaml"
#  eval "shrecho \"$_text\""
}

function importShrendd {
  _import="${1}:::"
  _library=$(echo "$_import" | cut -d':' -f1)
  _template=$(echo "$_import" | cut -d':' -f2)
  _version=""
  _type=$(echo "$_import" | cut -d':' -f3)
  _map_name=$(echo "$_import" | cut -d':' -f4)
  if [ -z "$_library" ] || [ "$_library" == "null" ]; then
    shrenddEcho "${_TEXT_ERROR}looks like you didn't even specify the library.${_CLEAR_TEXT_COLOR}\nimportShrendd must specify the artifact using the pattern: <library>:<template_file>:[version]:[type]"
    exit 1
  fi
  if [ -z "$_template" ] || [ "$_template" == "null" ]; then
    shrenddEcho "${_TEXT_ERROR}looks like you didn't specify the template file.${_CLEAR_TEXT_COLOR}\nimportShrendd must specify the artifact using the pattern: <library>:<template_file>:[version]:[type]"
    exit 1
  fi
  if [ -z "$_version" ] || [ "$_version" == "null" ]; then
    _version=$(shrenddOrDefault "shrendd.library.$_library.version")
  fi
  if [ -z "$_version" ] || [ "$_version" == "null" ]; then
    _version="latest"
  fi
  if [ -z "$_type" ] || [ "$_type" == "null" ]; then
    _type=$(shrenddOrDefault "shrendd.library.$_library.type")
  fi
  if [ -z "$_type" ] || [ "$_type" == "null" ]; then
    _type="text"
  fi
  _cache_dir="$(shrenddOrDefault "shrendd.library.cache.dir")"
  _bank="$_cache_dir/$_library/$_version"
  if [[ "$_library" == "this" ]] || [[ "$_MODULE_DIR" == *"$_library" ]]; then
    _bank="$_SHRENDD_DEPLOY_DIRECTORY"
  fi
  if [[ "${is_offline}" == "false" ]]; then
    cloneLibrary "$_library" "$_version" "$_bank" "$_template"
  fi
  if [ $# -lt 2 ]; then
    _current=$SECONDS
    shrenddLog "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n           importing shrendd ($_current): $_type"
    eval "importShrendd_$_type \"$_bank/$_template\" \"$_library\" \"$_template\" \"$_map_name\""
    shrenddLog "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n           finished imported ($_current): $_type"
  else
    shrenddEcho "$_bank/$_template"
  fi
}
