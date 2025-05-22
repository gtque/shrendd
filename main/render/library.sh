#!/bin/bash

export _latest_libs=" "

function devDLib {
  _cdir=$(pwd)
  cd $2
  zip -rq "$1" "./"
  cd $_cdir
}

function curlDLib {
  curl --output "$1" -L "$2" $3
}

function wgetDLib {
  wget --output-document="$1" "$2" $3
}

function cloneLibrary {
  _library="$1"
  _version="$2"
  _bank="$3"

  _xerox=$(shrenddOrDefault "shrendd.library.$_library.get.method")
  _xerox_settings=$(shrenddOrDefault "shrendd.library.$_library.get.parameters")
  _xerox_default="false"

  if [ -z "$_xerox" ] || [ "$_xerox" == "null" ]; then
    _xerox=$(shrenddOrDefault "shrendd.library.default.get.method")
  fi
  if [ -z "$_xerox_settings" ] || [ "$_xerox_settings" == "null" ]; then
    _xerox_settings=$(shrenddOrDefault "shrendd.library.default.get.parameters")
  fi

  #should probably support a forced update of libraries
  if [ "$_version" == "latest" ]; then
    if [ "$_latest_libs" != *" $_library "* ]; then
      #really need to add a cache timeout for latest...
      rm -rf "$_bank"
      export _latest_libs="${_latest_libs}${_library} "
    fi
  fi
  if [ -d $_bank ]; then
    :
  else
    mkdir -p "$_bank"
    #should support an offline mode here
    eval "$_xerox \"$_bank/$_library.zip\" \"$(shrenddOrDefault "shrendd.library.$_library.get.src")\" \"$_xerox_settings\""
    unzip -aoq "$_bank/$_library.zip" -d "$_bank"
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
  _bank="$(shrenddOrDefault "shrendd.library.cache.dir")/$_library/$_version"
  cloneLibrary "$_library" "$_version" "$_bank"
  eval "importShrendd_$_type \"$_bank/$_template\" \"$_library\" \"$_template\""
}
