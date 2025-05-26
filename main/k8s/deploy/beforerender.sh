#!/bin/bash
set -euo pipefail

function importShrendd_K8sScript {
#  echo "importing k8s script..."
#  _import="${1}:::"
#  _library=$(echo "$_import" | cut -d':' -f1)
#  _template=$(echo "$_import" | cut -d':' -f2)
#  _version=""
#  _type=$(echo "$_import" | cut -d':' -f3)
#  if [ -z "$_library" ] || [ "$_library" == "null" ]; then
#    echo -e "${_TEXT_ERROR}looks like you didn't even specify the library.${_CLEAR_TEXT_COLOR}\nimportShrendd must specify the artifact using the pattern: <library>:<template_file>:[version]:[type]"
#    exit 1
#  fi
#  if [ -z "$_template" ] || [ "$_template" == "null" ]; then
#    echo -e "${_TEXT_ERROR}looks like you didn't specify the template file.${_CLEAR_TEXT_COLOR}\nimportShrendd must specify the artifact using the pattern: <library>:<template_file>:[version]:[type]"
#    exit 1
#  fi
#  if [ -z "$_version" ] || [ "$_version" == "null" ]; then
#    _version=$(shrenddOrDefault "shrendd.library.$_library.version")
#  fi
#  if [ -z "$_version" ] || [ "$_version" == "null" ]; then
#    _version="latest"
#  fi
#  _the_script="$(importShrendd "${1}" "extract")"
  if [ $# -lt 4 ]; then
#    echo "#used basename"
    _the_name=$(basename "$_template")
  else
    if [ -z "$4" ]; then
#      echo "#used baename because the value was empty"
      _the_name=$(basename "$_template")
    else
#      echo "#should be using the given name"
      _the_name="$4"
    fi
  fi
  export _text=$(configify "$1")
  #echo "#$1"
#  echo -e "the text:$_text"
  _temp_yaml="$RENDER_DIR/temp/$2/$3"
  _temp_yaml_dirs=$(echo "${_temp_yaml%/*}")
#  echo "#temp path: $_temp_yaml_dirs"

#  echo "#must merge: $_temp_yaml"
#  export _merge_yaml="${_merge_yaml}\n$_temp_yaml"
#  doEval "$_text" "$_temp_yaml"

#  export _file=$(cat $_the_script)
  if [ -n "$_text" ]; then
#    echo "#the path: $_the_script"
  #  yq -i ".${_yq_name} += env(_template_stub)" $_spawn_path
    mkdir -p "$_temp_yaml_dirs"
    _yq=$(yq --null-input ".data.[\"$_the_name\"] += strenv(_text)")
    #echo -e "#temp yaml\n$_yq\n#end"
#    echo -e "#thescrips:\n$_yq\n#endscripts"
#    exit 1
#    _temp_yaml_dirs="$RENDER_DIR"
    _temp_yaml_dirs=$(echo "$RENDER_DIR/temp/${_template%/*}")
  #  echo "#temp path: $_temp_yaml_dirs"
#    mkdir -p "$_temp_yaml_dirs"
    if [ -n "${_merge_yaml+x}" ] && [ "$_merge_yaml" == "false" ]; then
      rm -rf "$RENDER_DIR/temp/merge_yaml"
    fi
    export _merge_yaml="true"
#    echo -e "$_yq" >> "$RENDER_DIR/temp/$_template"
#    echo "#should have written to: $RENDER_DIR/temp/$_template.yml"
    echo "$_temp_yaml.yml:data.shrend_place_holder" >> "$RENDER_DIR/temp/merge_yaml"
#    echo "$RENDER_DIR/temp/$_template.yml" >> "$RENDER_DIR/temp/merge_yaml"
    doEval  "$(echo -e "$_yq")" "$_temp_yaml.yml"
  fi
}