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

  if [[ "$FORCE_SHRENDD_UPDATES" == "true" ]]; then
    rm -rf "$_bank"
  fi

  #should probably support a forced update of libraries
  if [ "$_version" == "latest" ] && [ "$_xerox" != "getThis" ]; then
    if [ "$_latest_libs" != *" $_library "* ]; then
      #really need to add a cache timeout for latest...
      rm -rf "$_bank"
      export _latest_libs="${_latest_libs}${_library} "
    fi
  fi
  _destination="$_bank/$_library.zip"
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
  eval "echo -e \"$_text\""
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
    rm -rf "$RENDER_DIR/temp/merge_yaml"
  fi
  export _merge_yaml="true"
  echo "$_temp_yaml" >> "$RENDER_DIR/temp/merge_yaml"
  doEval "$_text" "$_temp_yaml"
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
    echo -e "${_TEXT_ERROR}looks like you didn't even specify the library.${_CLEAR_TEXT_COLOR}\nimportShrendd must specify the artifact using the pattern: <library>:<template_file>:[version]:[type]"
    exit 1
  fi
  if [ -z "$_template" ] || [ "$_template" == "null" ]; then
    echo -e "${_TEXT_ERROR}looks like you didn't specify the template file.${_CLEAR_TEXT_COLOR}\nimportShrendd must specify the artifact using the pattern: <library>:<template_file>:[version]:[type]"
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
    eval "importShrendd_$_type \"$_bank/$_template\" \"$_library\" \"$_template\" \"$_map_name\""
  else
    echo "$_bank/$_template"
  fi
}
