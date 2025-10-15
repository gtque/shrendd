#!/bin/bash
set -euo pipefail

if [ -f "$SHRENDD_DIR/render/${deploy_action}.sh" ]; then
  source "$SHRENDD_DIR/render/${deploy_action}.sh"
fi

if [ "$SHRENDD_EXTRACT" == "true" ] || [ -n "$SHRENDD_SPAWN" ]; then
  source  "$SHRENDD_DIR/render/template.sh"
fi

source  "$SHRENDD_DIR/render/library.sh"

export _SOURCED_CONFIG_SRC=" "

function stageLeft {
  _check="_MODULE_DIR"
  if [ -z "${!_check+x}" ]; then
    :
  else
    cd "$_MODULE_DIR"
    #loop over all types and delete the renders
    for _target in $targets; do
      targetDirs "$_target"
      if [ -d "$RENDER_DIR" ]; then
        echo "deleting $RENDER_DIR"
        shrenddLog "stageLeft: rm ${RENDER_DIR}"
        rm -rf "$RENDER_DIR"
      fi
    done
  fi
}

function targetDirs {
  export TEMPLATE_DIR=$(shrenddOrDefault "shrendd.$1.template.dir")
  if [ -z "$TEMPLATE_DIR" ] || [ "$TEMPLATE_DIR" == "null" ]; then
    export TEMPLATE_DIR=$(shrenddOrDefault "shrendd.default.template.dir")
  fi
  shrenddEchoIfNotSilent "template directory: $TEMPLATE_DIR"
  _build_or_render="render"
  if [[ "${SKIP_RENDER}" == "true" ]]; then
    _build_or_render="build"
  fi
  export RENDER_DIR=$(shrenddOrDefault "shrendd.$1.${_build_or_render}.dir")
  if [ -z "$RENDER_DIR" ] || [ "$RENDER_DIR" == "null" ]; then
    export RENDER_DIR=$(shrenddOrDefault "shrendd.default.${_build_or_render}.dir")
  fi
}

#first parameter should be deployment target/type, ie: k8s, tf, etc...
function checkRenderDirectory {
  printf "checking for render directory: $RENDER_DIR.\n"
  if [ -z "$RENDER_DIR" ] || [ "$RENDER_DIR" == "null" ]; then
    shrenddEchoIfNotSilent "creating a temporary render directory"
    export RENDER_DIR=$(mktemp -d)
  else
    if [ -d "$RENDER_DIR" ]; then
      shrenddEchoIfNotSilent "rendered folder already exists, clearing directory."
      shrenddLog "checkRenderDirectory: rm ${RENDER_DIR}"
      rm -rf "$RENDER_DIR"
    fi
    mkdir -p "$RENDER_DIR"
  fi
}

#first parameter should be deployment target/type, ie: k8s, tf, etc...
function render {
  prePostAfter "$1" "beforerender"
  prePostRender "$1" "beforerender"
  if [ "$SKIP_TEMPLATE" == "false" ]; then
    shrenddEchoIfNotSilent "${_TEXT_INFO}rendering templates${_CLEAR_TEXT_COLOR}"
    doRender "$TEMPLATE_DIR"
  else
    shrenddEchoWarning "skipping template rendering"
  fi
  prePostRender "$1" "afterrender"
  prePostAfter "$1" "afterrender"
}

function prePostAfter {
  if [ -f "$_SHRENDD_DEPLOY_DIRECTORY/$1/$deploy_action/$2.sh" ]; then
    shrenddEchoIfNotSilent "prePostAfter: processing $_SHRENDD_DEPLOY_DIRECTORY/$1/$deploy_action/$2.sh"
    source "$_SHRENDD_DEPLOY_DIRECTORY/$1/$deploy_action/$2.sh"
  else
    shrenddEchoIfNotSilent "prePostAfter: no $_SHRENDD_DEPLOY_DIRECTORY/$1/$deploy_action/$2.sh, nothing to do."
  fi
}

function prePostRender {
  if [ -f "$SHRENDD_DIR/$1/$deploy_action/$2.sh" ]; then
    shrenddEchoIfNotSilent "prePostRender: processing $SHRENDD_DIR/$1/$deploy_action/$2.sh"
    source "$SHRENDD_DIR/$1/$deploy_action/$2.sh"
  else
    shrenddEchoIfNotSilent "prePostRender: no $SHRENDD_DIR/$1/$deploy_action/$2.sh"
  fi
}

function doDeploy {
  prePostAfter "$1" "pre"
  if [ "$SKIP_STANDARD" == "false" ]; then
    shrenddEchoIfNotSilent "running standard setup."
    if [ -f "$SHRENDD_DIR/$1/${deploy_action}/deploy.sh" ]; then
      source "$SHRENDD_DIR/$1/${deploy_action}/deploy.sh"
    fi
  else
    shrenddEchoIfNotSilent "skipping standard $1/$deploy_action"
  fi
  prePostAfter "$1" "post"
}

function initConfig {
  if [ -z "$_SHRENDD_CONFIG" ]; then
    shrenddEchoIfNotSilent "no shrendd_config"
    _config_keys=""
  else
    _config_keys=$(keysFor "$_SHRENDD_CONFIG")
  fi
  if [ -z "$_PROVIDED_CONFIG" ]; then
    shrenddEchoIfNotSilent "no provided config"
    _provided_keys=""
  else
    _provided_keys=" $(keysFor "$_PROVIDED_CONFIG") "
  fi
  shrenddEchoIfNotSilent "${_TEXT_INFO}configuring:${_CLEAR_TEXT_COLOR}"
  _initialized="true"
  if [[ "${SHRENDD_EXTRACT}" == "true" ]] || [[ "${SKIP_RENDER}" == "true" ]]; then
    return
  fi
  for _config_key in $_config_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _name=$(trueName "$_config_key")
    _yq_name=$(yqName "$_config_key")
    _provided_keys=$(echo "$_provided_keys" | sed -e "s/ $_config_key / /g")
    _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_yq_name" -)
    _template_value=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" -)
    _suppressWarning=$(echo "$_template_value" | yq e ".suppressWarning" -)
    _neverSpawn=$(echo "$_template_value" | yq e ".neverSpawn" -)
    if [[ "$_suppressWarning" == "null" ]] || [[ "$_suppressWarning" != "true" ]]; then
      _suppressWarning="false"
    fi
    if [[ "$_neverSpawn" == "null" ]] || [[ "$_neverSpawn" != "true" ]]; then
      _neverSpawn="false"
    fi
    _is_sensitive="false"
    if [ -z "$_template_value" ]; then
      :
    else
      _is_sensitive=$(echo "$_template_value" | yq e ".sensitive" -)
      if [ "${_value}" == "null" ]; then
        shrenddEchoIfNotSilent "  ${_TEXT_WARN}${_yq_name}${_CLEAR_TEXT_COLOR} was null, checking if required or default present."
        _value_required=$(echo "$_template_value" | yq e ".required" -)
        _value_description=$(echo "$_template_value" | yq e ".description" -)
        if [ "$_value_description" == "null" ]; then
          _value_description=""
        fi
        if [ "${_value_required}" == "true" ] && [ "$_IGNORE_REQUIRED" == "false" ]; then
          shrenddEchoError "  \"$_config_key\" is required but was not provided. Description: $_value_description"
          _initialized="false"
        else
          _value_default=$(echo "$_template_value" | yq e ".default" -)
          if [ "${_value_default}" == "null" ]; then
            if [[ "${_strict}" == "true" ]] && [[ "$_suppressWarning" != true ]] ; then
              shrenddEchoError "\"$_config_key\" is not required and was not provided and no default has been defined. Description: $_value_description"
              _initialized="false"
            else
              if [[ "$_suppressWarning" != true ]]; then
                shrenddEchoWarning "\"$_config_key\" is not required and was not provided and no default has been defined. Description: $_value_description"
              else
                shrenddEchoIfNotSilent "suppressed warning: \"$_config_key\" is not required and was not provided and no default has been defined. Description: $_value_description"
              fi
            fi
          else
            if [[ "$_suppressWarning" != true ]]; then
              shrenddEchoWarning "\"$_config_key\" is not required and was not provided, so the default was used. Description: $_value_description"
            else
              shrenddEchoIfNotSilent "\"$_config_key\" is not required and was not provided, so the default was used. Description: $_value_description"
            fi
            _value="${_value_default}"
          fi
        fi
      fi
    fi
    if [ "${_value}" == "null" ]; then
      shrenddEchoIfNotSilent "${_TEXT_WARN}not initializing> \"$_config_key\"${_CLEAR_TEXT_COLOR}"
    else
      if [ "$_is_sensitive" == "true" ]; then
        shrenddEchoIfNotSilent "${_TEXT_DEBUG}initializing> \"$_config_key\": $_name: ${_TEXT_INFO}*****${_CLEAR_TEXT_COLOR}"
        _value_t=""
        if [[ -z "${_value}" ]] || [[ "${_value}" == "" ]]; then
          _value_t=""
        else
          #handle new lines in sensitive values for masking
          _value_t=$(echo "${_value}" | sed "s/\./\\./g" | sed ':a;N;$!ba;s/\n/'$_NEW_LINE_PLACE_HOLDER'/g' | sed ':a;N;$!ba;s/\r//g')
        fi
        if [[ -n "${_value_t}" ]] && [[ "${_value_t}" != "\"\"" ]]; then
          if [ -z "$_TUXEDO_MASK" ]; then
            :
          else
            export _TUXEDO_MASK="$_TUXEDO_MASK;"
          fi
          export _TUXEDO_MASK="${_TUXEDO_MASK}s/${_value_t}/*****/g"
        fi
      else
        shrenddEchoIfNotSilent "${_TEXT_DEBUG}initializing> \"$_config_key\": $_name: ${_TEXT_INFO}$_value${_CLEAR_TEXT_COLOR}"
      fi
      shrenddEchoIfNotSilent "\texported $_name"
      export $_name="$_value"
    fi
  done

  for _config_key in $_provided_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _yq_name=$(yqName "$_config_key")
    if [[ "${_strict}" == "true" ]]; then
      shrenddEchoError "\"$_config_key\" was provided but not defined in the config template."
      _initialized="false"
    else
      _name=$(trueName $_config_key)
      _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_yq_name" -)
      shrenddEchoWarning "${_TEXT_DEBUG}initializing> \"$_config_key\": $_name: ${_TEXT_INFO}$_value\n  ${_TEXT_WARN}if this is a sensitive value, you should add it to the config-template.yml file and mark it as sensitive.${_CLEAR_TEXT_COLOR}"
      shrenddEchoWarning "\"$_config_key\" was provided but not defined in the config template."
      export $_name="$_value"
    fi
  done
  if [ "$_initialized" == "false" ]; then
    shrenddEchoIfNotSilent "${_TEXT_ERROR}something was missing in the config template, please update the config template and try again.${_CLEAR_TEXT_COLOR}"
    exit 1
  else
    shrenddEchoIfNotSilent "${_TEXT_INFO}configuration complete.${_CLEAR_TEXT_COLOR}"
  fi
}

function unConfig {
  _config_keys=$(keysFor "$_SHRENDD_CONFIG")
  _provided_keys="$(keysFor "$_PROVIDED_CONFIG") "
  shrenddEchoIfNotSilent "unwinding configuration:"
  _initialized="true"
  for _config_key in $_config_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _name=$(trueName "$_config_key")
    _yq_name=$(yqName "$_config_key")
    _provided_keys=$(echo "$_provided_keys" | sed -e "s/$_config_key //g")
    _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_yq_name" -)
    if [ "${_value}" == "null" ]; then
      shrenddEchoIfNotSilent "  \"$_config_key\" was null, checking if required or default present."
      _template_value=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" -)
      _value_required=$(echo "$_template_value" | yq e ".required" -)
      if [ "${_value_required}" == "true" ]; then
        shrenddEchoError "  \"$_config_key\" is required but was not provided."
#        echo "\"$_config_key\" is required but was not provided." >> "$_DEPLOY_ERROR_DIR/render_error.log"
        _initialized="false"
      else
        _value_default=$(echo "$_template_value" | yq e ".default" -)
        if [ "${_value_default}" == "null" ]; then
#          echo "  \"$_config_key\" no default has been defined."
          if [ "${_strict}" == "true" ]; then
            shrenddEchoError "\"$_config_key\" is not required and was not provided and no default has been defined."
            _initialized="false"
          else
            shrenddEchoWarning "\"$_config_key\" is not required and was not provided and no default has been defined."
          fi
        else
          shrenddEchoIfNotSilent "  \"$_config_key\" using default value"
          _value="${_value_default}"
        fi
      fi
    fi
    if [ "${_value}" == "null" ]; then
      shrenddEchoIfNotSilent "no need to unwind> \"$_config_key\""
    else
      shrenddEchoIfNotSilent "unwinding> \"$_config_key\": $_name: $_value"
      unset "$_name"
    fi
  done
  for _config_key in $_provided_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _yq_name=$(yqName "$_config_key")
#    shrenddEchoIfNotSilent "  \"$_config_key\" not defined in the template."
    if [ "${_strict}" == "true" ]; then
      shrenddEchoError "\"$_config_key\" not defined in the template."
      _initialized="false"
    else
      _name=$(trueName "$_config_key")
      _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_yq_name" -)
      shrenddEchoIfNotSilent "  unwinding> \"$_config_key\": $_name: $_value"
      unset "$_name"
      shrenddEchoWarning "\"$_config_key\" not defined in the template."
    fi
  done
  if [ "$_initialized" == "false" ]; then
    shrenddEchoIfNotSilent "something was missing in the template, please update the template and try again."
    exit 1
  fi
}

function getSecret {
  _secret=$(getConfig "$1")
  if [ $? -ne 0 ]; then
    echo -e "${_secret}"
  else
    _secret=$(echo -e "$_secret" | base64)
    echo -e "$_secret"
  fi
}

#maybe set a flag somewhere to indicate config-template configuration and
#skip writing to file, and instead stuffing into yaml variable.
function getConfig {
  if [[ "${SKIP_RENDER}" == "true" ]]; then
    shrenddLog "getConfig: SKIP_RENDER is true, returning raw variable: $1"
    echo "\$(getConfig $1)"
    return 0
  fi

  _name=$(trueName "$1")
  if [ -z "${!_name+x}" ]; then
    echo "error getting config for $1" >> "$_DEPLOY_ERROR_DIR/config_error.log"
    shrenddLog "\${${1}}"
    echo -e "\${${1}}"
    return 1
  else
    _value=$(eval "echo -e \"${!_name}\"")
    echo -e "$_value"
  fi
}

function configify {
  cat "$1" | sed -e "s/\\\${\([^}]*\)}/\\\$(getConfig \"\1\")/g"
}

function getAsIs {
  _name=$(trueName "$1")
  if [ -z "${!_name+x}" ]; then
    echo "error getting as is config for $1" >> "$_DEPLOY_ERROR_DIR/config_error.log"
    shrenddLog "\${${1}}"
    echo -e "\${${1}}"
    return 1
  else
    echo -e "${!_name}"
  fi
}

function getConfigOrEmpty {
  if [[ "${SKIP_RENDER}" == "true" ]]; then
    shrenddLog "getConfig: SKIP_RENDER is true, returning raw variable: $1"
    echo "\$(getConfigOrEmpty $1)"
    return 0
  fi
  _check=$(trueName "$1")
  shrenddLog "truename for config: $_check"
  if [ -z "${!_check+x}" ]; then
    shrenddLog " was empty"
  else
    shrenddLog " was not empty?"
    getConfig "$1"
  fi
}

function toYaml {
  echo -e "$1" | yq e '. | to_yaml' -
#  export _template_stub="$1"
#  yq --null-input "$_template_stub"
}

function padding {
  num_spaces=$(($1 * $2))
  if [ -z "$num_spaces" ]; then
    num_spaces="0"
  fi
  spaces=$(printf "%${num_spaces}s")
  echo "$spaces"
}

function pad {
  _padding=$(padding "0" "$(shrenddOrDefault "shrendd.k8s.yaml.padding")")
  if [ -n "${2+x}" ]; then
    if [ "$2" -gt 0 ]; then
      _padding=$(padding "$2" "$(shrenddOrDefault "shrendd.k8s.yaml.padding")")
    fi
  fi
  echo -e -n "$1" | sed -e "s/^\(.*\)/$_padding\1/g"
}

function loadConfig {
  _the_module="$1"
  if [ "$_the_module" == "." ]; then
      export _SHRENDD="$_SHRENDDO"
    else
      _module_shrendd_yaml=$(shrenddOrDefault "shrendd.module.$_the_module.properties" || echo "./$_the_module/shrendd.yml")
      if [ "${_module_shrendd_yaml}" == "null" ]; then
        _module_shrendd_yaml="./$_the_module/shrendd.yml"
      fi
      shrenddEchoIfNotSilent "looking for: $_module_shrendd_yaml"
      if [ -f "$_module_shrendd_yaml" ]; then
        shrenddEchoIfNotSilent "found module's shrendd propeties, will use values defined there, if no value specified, will use default values."
        export _SHRENDD=$(echo "$_SHRENDDO" | yq eval-all '. as $item ireduce ({}; . * $item )' - "$_module_shrendd_yaml")
      else
        shrenddEchoIfNotSilent "no shrendd.yml found for the module, using defaults. For more information on configuring shrendd, please see:"
        export _SHRENDD="$_SHRENDDO"
      fi
    fi

    if [ "$_config" == "false" ]; then
      shrenddEchoIfNotSilent "${_TEXT_WARN}sure, I can render without a config file, but it's much easier if there is one.${_CLEAR_TEXT_COLOR}"
      shrenddEchoError "rendered ${_TEXT_WARN}without${_CLEAR_TEXT_COLOR} a config."
    fi
    export _config_path="$(shrenddOrDefault shrendd.config.path)/${_config}"

    if [ -f "$_config_path" ]; then
      if [[ "$_SHRENDD_UNWIND" == "true" && "$_reconfigured" == "false" && "$_config_path_proper" != "$_config_path" ]]; then
        shrenddEchoIfNotSilent "looks like i need to unwind some configs first..."
        unConfig
        export _reconfigured="true"
      fi
      if [[ "$_reconfigured" == "true" ||  "$_config_path_proper" != "$_config_path" ]]; then
        if [ "$(shrenddOrDefault "shrendd.config.validate")" == "true" ]; then
          export _SHRENDD_CONFIG=$(cat "$(shrenddOrDefault "shrendd.config.definition")")
        else
          export _SHRENDD_CONFIG=$(cat "$_config_path")
        fi
        export _PROVIDED_CONFIG=$(cat "$_config_path")
        shrenddEchoIfNotSilent "found $_config."
        initConfig
        shrenddEchoIfNotSilent "done initializing"
        export _reconfigured="false"
      fi
    else
      shrenddEchoIfNotSilent "no $_config found, no custom parameters defined."
      export _SHRENDD_CONFIG=""
    fi
}

function unwindConfig {
    if [ -f "$_config_path" ]; then
  #    if [ "$(shrenddOrDefault "shrendd.config.validate")" == "true" ]; then
  #      export _SHRENDD_CONFIG=$(cat "$(shrenddOrDefault "shrendd.config.definition")")
  #    else
  #      export _SHRENDD_CONFIG=$(cat $_config_path)
  #    fi
  #    export _PROVIDED_CONFIG=$(cat $_config_path)
  #    echo "found $_config."
      shrenddEchoIfNotSilent "config was found, checking to see if it should be unwound."
      if [[ "$_SHRENDD_UNWIND" == "true" && "$_config_path_proper" != "$_config_path" ]]; then
        shrenddEchoIfNotSilent "unwinding config"
        unConfig
        export _reconfigured="false"
      else
        shrenddEchoIfNotSilent "sharing config(s) between modules, but only those not overridden by the current module."
      fi
    else
      shrenddEchoIfNotSilent "no $_config, nothing to unset"
    fi
}

function sourceConfigs {
  _config_src="$(shrenddOrDefault "shrendd.config.src")"
  shrenddEchoIfNotSilent "${_TEXT_INFO}looking for sources: $_config_src${_CLEAR_TEXT_COLOR}"
  if [ -d "$_config_src" ]; then
    _config_src_files=$(find "$_config_src" -type f -print)
    while IFS= read -r fname; do
      _src_file="$(echo "$(pwd)$fname" | sed -e "s/\/\.\//\//g")"
      if [ "$_SOURCED_CONFIG_SRC" != *" $_src_file "* ]; then
        shrenddEchoIfNotSilent "  sourcing: ${_TEXT_INFO}$_src_file${_CLEAR_TEXT_COLOR}"
        _SOURCED_CONFIG_SRC="$(echo "$_SOURCED_CONFIG_SRC $_src_file")"
        source "$fname"
      fi
    done <<< $_config_src_files
  fi
  shrenddEchoIfNotSilent "${_TEXT_INFO}sourced: $_config_src${_CLEAR_TEXT_COLOR}"
}

function moduleRender {
  export _the_module="$1"
  shrenddEchoIfNotSilent "rendering: $_the_module"
  sourceConfigs
  if [ -f "$_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/pre.sh" ]; then
    shrenddEchoIfNotSilent "moduleRender: processing $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/pre.sh"
    source "$_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/pre.sh"
  else
    shrenddEchoIfNotSilent "moduleRender: no $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/pre.sh"
  fi

  for _target in $targets; do
    export target="$_target"
    shrenddEchoIfNotSilent "${_TEXT_INFO}---------------- shrendd: $target ----------------${_CLEAR_TEXT_COLOR}"
    shrenddEchoIfNotSilent "initializing target template directory"
    targetDirs "$target"
    shrenddEchoIfNotSilent "initializing rendering directory"
    checkRenderDirectory "$target"
    shrenddEchoIfNotSilent "rendering to: $RENDER_DIR"
    render "$target"
    shrenddLog "moduleRender: rm ${RENDER_DIR}/temp"
    rm -rf "$RENDER_DIR/temp"
    shrenddEchoIfNotSilent "${_TEXT_INFO}render complete${_CLEAR_TEXT_COLOR}"
    if [ "$SKIP_DEPLOY" == "false" ]; then
      shrenddEchoIfNotSilent "deploying $target"
      doDeploy "$target"
    else
      shrenddEchoIfNotSilent "skipping deploy"
    fi
  done

  if [ -f "$_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/post.sh" ]; then
    shrenddEchoIfNotSilent "moduleRender: processing $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/post.sh"
    source "$_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/post.sh"
  else
    shrenddEchoIfNotSilent "moduleRender: no $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/post.sh"
  fi
}

function moduleGetProperty {
  export _the_module="$1"

  for _target in $targets; do
    export target="$_target"
    shrenddLog "${target}: $(shrenddOrDefault "$_property")" "sensitive"
    echo "${target}: $(shrenddOrDefault "$_property")"
  done
}

function shrenddDeployRun {
  export _DEPLOY_ERROR_DIR="$SHRENDD_DIR/errors"
  if [ -d "$_DEPLOY_ERROR_DIR" ]; then
    if [[ "$PRESERVE_LOG" == "true" ]]; then
      shrenddEchoIfNotSilent "preserving log files in $_DEPLOY_ERROR_DIR"
    else
      shrenddEchoIfNotSilent "clearing out old log files in $_DEPLOY_ERROR_DIR"
      rm -rf "$_DEPLOY_ERROR_DIR"/*
      shrenddLog "shrenddDeployRun: rm ${_DEPLOY_ERROR_DIR}/*"
    fi
  else
    mkdir "$_DEPLOY_ERROR_DIR"
  fi

  if [ "$_requested_help" == "true" ]; then
    if [ "$_is_debug" == true ]; then
      shrenddEchoIfNotSilent "config: $_config"
      shrenddEchoIfNotSilent "module: $_module"
    fi
    exit 0
  fi

  export _SHRENDDO="$_SHRENDD"
  export _configo="$_config"
  export _SHRENDD_UNWIND=$(shrenddOrDefault "shrendd.config.unwind")
  export _SHRENDD_CONFIG_TEMPLATE_PATH=""
  if [ "$_config" != "false" ]; then
    export _config_path_proper="$(shrenddOrDefault shrendd.config.path)/${_config}"
    export _SHRENDD_CONFIG_TEMPLATE_PATH="$(shrenddOrDefault "shrendd.config.definition")"
    if [ "$(shrenddOrDefault "shrendd.config.validate")" == "true" ]; then
      shrenddEchoIfNotSilent "validating shrend definition..."
      if [ -f "$(shrenddOrDefault "shrendd.config.definition")" ]; then
        export _SHRENDD_CONFIG=$(cat "$(shrenddOrDefault "shrendd.config.definition")")
      else
        VAR="$(shrenddOrDefault "shrendd.config.definition")"
        DIR="."
        if [[ "$VAR" == *"/"* ]]; then
          DIR=${VAR%/*}
          if [ -d "$DIR" ]; then
            :
          else
            mkdir -p "$DIR"
          fi
        fi
        echo "" > "$VAR"
        export _SHRENDD_CONFIG=""
      fi
    else
      shrenddEchoIfNotSilent "shrendd proper"
      if [ -f "$_config_path_proper" ]; then
        export _SHRENDD_CONFIG=$(cat "$_config_path_proper")
      else
        VAR="$_config_path_proper"
        DIR="."
        if [[ "$VAR" == *"/"* ]]; then
          DIR=${VAR%/*}
          if [ -d "$DIR" ]; then
            :
          else
            mkdir -p "$DIR"
          fi
        fi
        echo "" > "$VAR"
        export _SHRENDD_CONFIG=""
      fi
    fi
    shrenddEchoIfNotSilent "provided config"
    if [ -f "$_config_path_proper" ]; then
      export _PROVIDED_CONFIG=$(cat "$_config_path_proper")
    else
      VAR="$_config_path_proper"
      DIR="."
      if [[ "$VAR" == *"/"* ]]; then
        DIR=${VAR%/*}
        if [ -d "$DIR" ]; then
          :
        else
          mkdir -p "$DIR"
        fi
      fi
      echo "" > "$VAR"
      export _PROVIDED_CONFIG=""
    fi
  fi
  export _reconfigured="false"
  export _STARTING_DIR="$(pwd)"
  export _IGNORE_REQUIRED="false"

  if [ "$SHRENDD_EXTRACT" == "true" ] || [ -n "$SHRENDD_SPAWN" ]; then
    doTemplate
  fi

  export _IGNORE_REQUIRED="false"
  if [[ "$deploy_action" != "skip" ]]; then
    initConfig
    for _specific_module in $_module; do
      loadConfig $_specific_module
      shrenddEchoIfNotSilent "switching to module: $_the_module"
      cd "$_the_module"
      export _MODULE_DIR="$(pwd)"
      export _SHRENDD_DEPLOY_DIRECTORY="$(shrenddOrDefault "shrendd.deploy.dir")"
      if [[ -n "$GET_PROPERTY" ]]; then
        initTargets
        properties="$(echo -e "$GET_PROPERTY")"
        _multiple_properties=""
        while IFS= read -r _property; do #for _property in $GET_PROPERTY; do
          if [[ "$_property" == "shrendd.targets" ]]; then
            echo "$targets"
            shrenddLog "$targets"
          else
            #echo "$(shrenddOrDefault "$_property")"
            if [[ -n "$_multiple_properties" ]]; then
              echo "<<<>>>"
              shrenddLog "<<<>>>"
            fi
            moduleGetProperty "$_property"
            _multiple_properties="true"
          fi
        done <<< $properties
        exit 0
      fi
      shrenddEchoIfNotSilent "shrendd deploy dir: $_SHRENDD_DEPLOY_DIRECTORY"
      shrenddEchoIfNotSilent "trying to load array of targets for: $_MODULE_DIR"
      initTargets
      moduleRender "$_specific_module"
      unwindConfig
      cd "$_STARTING_DIR"
    done
  fi
}
