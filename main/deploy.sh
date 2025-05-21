#!/bin/bash
set -euo pipefail

if [ -f $SHRENDD_WORKING_DIR/.shrendd/render/${deploy_action}.sh ]; then
  source $SHRENDD_WORKING_DIR/.shrendd/render/${deploy_action}.sh
fi

if [ "$SHRENDD_EXTRACT" == "true" ] || [ -n "$SHRENDD_SPAWN" ]; then
  source  $SHRENDD_WORKING_DIR/.shrendd/render/template.sh
fi

export _SOURCED_CONFIG_SRC=" "

function stageLeft {
  _check="_MODULE_DIR"
  if [ -z "${!_check+x}" ]; then
    :
  else
    cd $_MODULE_DIR
    #loop over all types and delete the renders
    for _target in $targets; do
      targetDirs $_target
      if [ -d "$RENDER_DIR" ]; then
        echo "deleting $RENDER_DIR"
        rm -rf $RENDER_DIR
      fi
    done
  fi
}

function targetDirs {
  export TEMPLATE_DIR=$(shrenddOrDefault "shrendd.$1.template.dir")
  if [ -z "$TEMPLATE_DIR" ] || [ "$TEMPLATE_DIR" == "null" ]; then
    export TEMPLATE_DIR=$(shrenddOrDefault "shrendd.default.template.dir")
  fi
  echo "template directory: $TEMPLATE_DIR"
  export RENDER_DIR=$(shrenddOrDefault "shrendd.$1.render.dir")
  if [ -z "$RENDER_DIR" ] || [ "$RENDER_DIR" == "null" ]; then
    export RENDER_DIR=$(shrenddOrDefault "shrendd.default.render.dir")
  fi
}

#first parameter should be deployment target/type, ie: k8s, tf, etc...
function checkRenderDirectory {
  printf "checking for render directory: $RENDER_DIR.\n"
  if [ -z "$RENDER_DIR" ] || [ "$RENDER_DIR" == "null" ]; then
    echo "creating a temporary render directory"
    export RENDER_DIR=$(mktemp -d)
  else
    if [ -d $RENDER_DIR ]; then
      echo "rendered folder already exists, clearing directory."
      rm -rf $RENDER_DIR
    fi
    mkdir -p $RENDER_DIR
  fi
}

#first parameter should be deployment target/type, ie: k8s, tf, etc...
function render {
  prePostAfter "$1" "beforerender"
  prePostRender "$1" "beforerender"
  if [ "$SKIP_TEMPLATE" == "false" ]; then
    echo -e "${_TEXT_INFO}rendering templates${_CLEAR_TEXT_COLOR}"
    doRender $TEMPLATE_DIR
  else
    echo -e "${_TEXT_WARN}skipping template rendering${_CLEAR_TEXT_COLOR}"
  fi
  prePostRender "$1" "afterrender"
  prePostAfter "$1" "afterrender"
}

function prePostAfter {
  if [ -f $_SHRENDD_DEPLOY_DIRECTORY/$1/$deploy_action/$2.sh ]; then
    echo "processing $_SHRENDD_DEPLOY_DIRECTORY/$1/$deploy_action/$2.sh"
    source $_SHRENDD_DEPLOY_DIRECTORY/$1/$deploy_action/$2.sh
  else
    echo "no $_SHRENDD_DEPLOY_DIRECTORY/$1/$deploy_action/$2.sh, nothing to do."
  fi
}

function prePostRender {
  if [ -f $SHRENDD_WORKING_DIR/.shrendd/$1/$deploy_action/$2.sh ]; then
    echo "processing $SHRENDD_WORKING_DIR/.shrendd/$1/$deploy_action/$2.sh"
    source $SHRENDD_WORKING_DIR/.shrendd/$1/$deploy_action/$2.sh
  else
    echo "no $SHRENDD_WORKING_DIR/.shrendd/$1/$deploy_action/$2.sh"
  fi
}

function doDeploy {
  prePostAfter "$1" "pre"
  if [ "$SKIP_STANDARD" == "false" ]; then
    echo "running standard setup."
    if [ -f $SHRENDD_WORKING_DIR/.shrendd/$1/${deploy_action}/deploy.sh ]; then
      source $SHRENDD_WORKING_DIR/.shrendd/$1/${deploy_action}/deploy.sh
    fi
  else
    echo "skipping standard $1/$deploy_action"
  fi
  prePostAfter "$1" "post"
}

function initConfig {
  if [ -z "$_SHRENDD_CONFIG" ]; then
    echo "no shrendd_config"
    _config_keys=""
  else
    _config_keys=$(keysFor "$_SHRENDD_CONFIG")
  fi
  if [ -z "$_PROVIDED_CONFIG" ]; then
    echo "no provided config"
    _provided_keys=""
  else
    _provided_keys="$(keysFor "$_PROVIDED_CONFIG") "
  fi
  echo -e "${_TEXT_INFO}configuring:${_CLEAR_TEXT_COLOR}"
  _initialized="true"
  for _config_key in $_config_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _name=$(trueName $_config_key)
    _yq_name=$(yqName "$_config_key")
    _provided_keys=$(echo "$_provided_keys" | sed -e "s/$_config_key //g")
    _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_yq_name" -)
    _template_value=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" -)
    _is_sensitive="false"
    if [ -z "$_template_value" ]; then
      :
    else
      _is_sensitive=$(echo "$_template_value" | yq e ".sensitive" -)
      if [ "${_value}" == "null" ]; then
        echo -e "  ${_TEXT_WARN}${_yq_name}${_CLEAR_TEXT_COLOR} was null, checking if required or default present."
        _value_required=$(echo "$_template_value" | yq e ".required" -)
        _value_description=$(echo "$_template_value" | yq e ".description" -)
        if [ "$_value_description" == "null" ]; then
          _value_description=""
        fi
        if [ "${_value_required}" == "true" ] && [ "$_IGNORE_REQUIRED" == "false" ]; then
          echo "  \"$_config_key\" is required but was not provided. Description: $_value_description"
          echo "\"$_config_key\" is required but was not provided. Description: $_value_description" >> $_DEPLOY_ERROR_DIR/render_error.log
          _initialized="false"
        else
          _value_default=$(echo "$_template_value" | yq e ".default" -)
          if [ "${_value_default}" == "null" ]; then
            echo "  \"$_config_key\" no default has been defined."
            if [ "${_strict}" == "true" ]; then
              echo "\"$_config_key\" is not required and was not provided and no default has been defined. Description: $_value_description" >> $_DEPLOY_ERROR_DIR/render_error.log
              _initialized="false"
            else
              echo "\"$_config_key\" is not required and was not provided and no default has been defined. Description: $_value_description" >> $_DEPLOY_ERROR_DIR/render_warning.log
            fi
          else
            echo "  \"$_config_key\" using default value"
            echo "\"$_config_key\" is not required and was not provided, so the default was used. Description: $_value_description" >> $_DEPLOY_ERROR_DIR/render_info.log
            _value="${_value_default}"
          fi
        fi
      fi
    fi
    if [ "${_value}" == "null" ]; then
      echo -e "${_TEXT_WARN}not initializing> \"$_config_key\"${_CLEAR_TEXT_COLOR}"
    else
      if [ "$_is_sensitive" == "true" ]; then
        echo -e "${_TEXT_DEBUG}initializing> \"$_config_key\": $_name: ${_TEXT_INFO}*****${_CLEAR_TEXT_COLOR}"
        if [ -z "$_TUXEDO_MASK" ]; then
          :
        else
          _TUXEDO_MASK="$_TUXEDO_MASK;"
        fi
        _value_t=$(echo "${_value}" | sed "s/\./\\./g" | sed ':a;N;$!ba;s/\n/'$_NEW_LINE_PLACE_HOLDER'/g' | sed ':a;N;$!ba;s/\r//g')
        _TUXEDO_MASK="${_TUXEDO_MASK}s/${_value_t}/*****/g"
      else
        echo -e "${_TEXT_DEBUG}initializing> \"$_config_key\": $_name: ${_TEXT_INFO}$_value${_CLEAR_TEXT_COLOR}"
      fi
      export $_name="$_value"
    fi
  done
  for _config_key in $_provided_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _yq_name=$(yqName "$_config_key")
    echo "  \"$_config_key\" was provided but not defined in the template."
    if [ "${_strict}" == "true" ]; then
      echo "\"$_config_key\" was provided but not defined in the template." >> $_DEPLOY_ERROR_DIR/render_error.log
      _initialized="false"
    else
      _name=$(trueName $_config_key)
      _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_yq_name" -)
      echo -e "${_TEXT_DEBUG}initializing> \"$_config_key\": $_name: ${_TEXT_INFO}$_value\n  ${_TEXT_WARN}if this is a sensitive value, you should add it to the config-template.yml file and mark it as sensitive.${_CLEAR_TEXT_COLOR}"
      export $_name="$_value"
      echo "\"$_config_key\" was provide but not defined in the template." >> $_DEPLOY_ERROR_DIR/render_warning.log
    fi
  done
  if [ "$_initialized" == "false" ]; then
    echo -e "${_TEXT_ERROR}something was missing in the template, please update the template and try again.${_CLEAR_TEXT_COLOR}"
    exit 1
  fi
}

function unConfig {
  _config_keys=$(keysFor "$_SHRENDD_CONFIG")
  _provided_keys="$(keysFor "$_PROVIDED_CONFIG") "
  echo "unwinding configuration:"
  _initialized="true"
  for _config_key in $_config_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _name=$(trueName $_config_key)
    _yq_name=$(yqName "$_config_key")
    _provided_keys=$(echo "$_provided_keys" | sed -e "s/$_config_key //g")
    _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_yq_name" -)
    if [ "${_value}" == "null" ]; then
      echo "  \"$_config_key\" was null, checking if required or default present."
      _template_value=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" -)
      _value_required=$(echo "$_template_value" | yq e ".required" -)
      if [ "${_value_required}" == "true" ]; then
        echo "  \"$_config_key\" is required but was not provided."
        echo "\"$_config_key\" is required but was not provided." >> $_DEPLOY_ERROR_DIR/render_error.log
        _initialized="false"
      else
        _value_default=$(echo "$_template_value" | yq e ".default" -)
        if [ "${_value_default}" == "null" ]; then
          echo "  \"$_config_key\" no default has been defined."
          if [ "${_strict}" == "true" ]; then
            echo "\"$_config_key\" is not required and was not provided and no default has been defined." >> $_DEPLOY_ERROR_DIR/render_error.log
            _initialized="false"
          else
            echo "\"$_config_key\" is not required and was not provided and no default has been defined." >> $_DEPLOY_ERROR_DIR/render_warning.log
          fi
        else
          echo "  \"$_config_key\" using default value"
          _value="${_value_default}"
        fi
      fi
    fi
    if [ "${_value}" == "null" ]; then
      echo "no need to unwind> \"$_config_key\""
    else
      echo "unwinding> \"$_config_key\": $_name: $_value"
      unset $_name
    fi
  done
  for _config_key in $_provided_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _yq_name=$(yqName "$_config_key")
    echo "  \"$_config_key\" not defined in the template."
    if [ "${_strict}" == "true" ]; then
      echo "\"$_config_key\" not defined in the template." >> $_DEPLOY_ERROR_DIR/render_error.log
      _initialized="false"
    else
      _name=$(trueName $_config_key)
      _value=$(echo "$_PROVIDED_CONFIG" | yq e ".$_yq_name" -)
      echo "  unwinding> \"$_config_key\": $_name: $_value"
      unset $_name
      echo "\"$_config_key\" not defined in the template." >> $_DEPLOY_ERROR_DIR/render_warning.log
    fi
  done
  if [ "$_initialized" == "false" ]; then
    echo "something was missing in the template, please update the template and try again."
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
  _name=$(trueName "$1")
  if [ -z "${!_name+x}" ]; then
    echo "error getting config for $1" >> $_DEPLOY_ERROR_DIR/config_error.log
    echo -e "\${${1}}"
    return 1
  else
      if [ -z "$_value" ] || [ "$_value" == "" ]; then
        echo ""
      else
        _value=$(eval "echo -e \"${!_name}\"")
        echo -e "$_value"
      fi
  fi
}

function getAsIs {
  _name=$(trueName "$1")
  if [ -z "${!_name+x}" ]; then
    echo "error getting config for $1" >> $_DEPLOY_ERROR_DIR/config_error.log
    echo -e "\${${1}}"
    return 1
  else
      if [ -z "$_value" ] || [ "$_value" == "" ]; then
        echo ""
      else
        echo -e "${!_name}"
      fi
  fi
}

function getConfigOrEmptyD {
  _check=$(trueName "$1")
  echo "truename for config: $_check"
  if [ -z "${!_check+x}" ]; then
    echo " was empty"
  else
    echo " was not empty?"
    getConfig "$1"
  fi
}

function getConfigOrEmpty {
  _check=$(trueName "$1")
  if [ -z "${!_check+x}" ]; then
    :
  else
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
      echo "looking for: $_module_shrendd_yaml"
      if [ -f $_module_shrendd_yaml ]; then
        echo "found module's shrendd propeties, will use values defined there, if no value specified, will use default values."
        export _SHRENDD=$(echo "$_SHRENDDO" | yq eval-all '. as $item ireduce ({}; . * $item )' - $_module_shrendd_yaml)
      else
        echo "no shrendd.yml found for the module, using defaults. For more information on configuring shrendd, please see:"
        export _SHRENDD="$_SHRENDDO"
      fi
    fi

    if [ "$_config" == "false" ]; then
      echo -e "${_TEXT_WARN}sure, I can render without a config file, but it's much easier if there is one.${_CLEAR_TEXT_COLOR}"
      echo "rendered ${_TEXT_WARN}without${_CLEAR_TEXT_COLOR} a config." >> $_DEPLOY_ERROR_DIR/render_warning.log
    fi
    export _config_path=$(shrenddOrDefault shrendd.config.path)/${_config}

    if [ -f $_config_path ]; then
      if [[ "$_SHRENDD_UNWIND" == "true" && "$_reconfigured" == "false" && "$_config_path_proper" != "$_config_path" ]]; then
        echo "looks like i need to unwind some configs first..."
        unConfig
        export _reconfigured="true"
      fi
      if [[ "$_reconfigured" == "true" ||  "$_config_path_proper" != "$_config_path" ]]; then
        if [ "$(shrenddOrDefault "shrendd.config.validate")" == "true" ]; then
          export _SHRENDD_CONFIG=$(cat "$(shrenddOrDefault "shrendd.config.definition")")
        else
          export _SHRENDD_CONFIG=$(cat $_config_path)
        fi
        export _PROVIDED_CONFIG=$(cat $_config_path)
        echo "found $_config."
        initConfig
        echo "done initializing"
        export _reconfigured="false"
      fi
    else
      echo "no $_config found, no custom parameters defined."
      export _SHRENDD_CONFIG=""
    fi
}

function unwindConfig {
    if [ -f $_config_path ]; then
  #    if [ "$(shrenddOrDefault "shrendd.config.validate")" == "true" ]; then
  #      export _SHRENDD_CONFIG=$(cat "$(shrenddOrDefault "shrendd.config.definition")")
  #    else
  #      export _SHRENDD_CONFIG=$(cat $_config_path)
  #    fi
  #    export _PROVIDED_CONFIG=$(cat $_config_path)
  #    echo "found $_config."
      echo "config was found, checking to see if it should be unwound."
      if [[ "$_SHRENDD_UNWIND" == "true" && "$_config_path_proper" != "$_config_path" ]]; then
        echo "unwinding config"
        unConfig
        export _reconfigured="false"
      else
        echo "sharing config(s) between modules, but only those not overridden by the current module."
      fi
    else
      echo "no $_config, nothing to unset"
    fi
}

function sourceConfigs {
  _config_src=$(shrenddOrDefault "shrendd.config.src")
  echo -e "${_TEXT_INFO}looking for sources: $_config_src${_CLEAR_TEXT_COLOR}"
  if [ -d $_config_src ]; then
    _config_src_files=$(find $_config_src -type f -print)
    while IFS= read -r fname; do
      _src_file="$(echo "$(pwd)$fname" | sed -e "s/\/\.\//\//g")"
      if [ "$_SOURCED_CONFIG_SRC" != *" $_src_file "* ]; then
        echo -e "  sourcing: ${_TEXT_INFO}$_src_file${_CLEAR_TEXT_COLOR}"
        _SOURCED_CONFIG_SRC=$(echo "$_SOURCED_CONFIG_SRC $_src_file")
        source $fname
      fi
    done <<< $_config_src_files
  fi
  echo -e "${_TEXT_INFO}sourced: $_config_src${_CLEAR_TEXT_COLOR}"
}

function moduleRender {
  export _the_module="$1"
  echo "rendering: $_the_module"
  sourceConfigs
  if [ -f $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/pre.sh ]; then
    echo "processing $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/pre.sh"
    source $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/pre.sh
  else
    echo "no $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/pre.sh"
  fi

  for _target in $targets; do
    export target="$_target"
    echo "deploying: $target"
    echo "initializing target template directory"
    targetDirs "$target"
    echo "initializing rendering directory"
    checkRenderDirectory "$target"
    echo "rendering"
    render "$target"
    rm -rf "$RENDER_DIR/temp"
    echo -e "${_TEXT_INFO}render complete${_CLEAR_TEXT_COLOR}"
    if [ "$SKIP_DEPLOY" == "false" ]; then
      echo "deploying $target"
      doDeploy "$target"
    else
      echo "skipping deploy"
    fi
  done

  if [ -f $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/post.sh ]; then
    echo "processing $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/post.sh"
    source $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/post.sh
  else
    echo "no $_SHRENDD_DEPLOY_DIRECTORY/$deploy_action/post.sh"
  fi
}

function shrenddDeployRun {
  export _DEPLOY_ERROR_DIR="$SHRENDD_WORKING_DIR/.shrendd/errors"
  if [ -d $_DEPLOY_ERROR_DIR ]; then
    rm -rf $_DEPLOY_ERROR_DIR/*
  else
    mkdir $_DEPLOY_ERROR_DIR
  fi

  if [ "$_requested_help" == "true" ]; then
    if [ "$_is_debug" == true ]; then
      echo "config: $_config"
      echo "module: $_module"
    fi
    exit 0
  fi

  export _SHRENDDO="$_SHRENDD"
  export _configo="$_config"
  export _SHRENDD_UNWIND=$(shrenddOrDefault "shrendd.config.unwind")
  export _SHRENDD_CONFIG_TEMPLATE_PATH=""
  if [ "$_config" != "false" ]; then
    export _config_path_proper=$(shrenddOrDefault shrendd.config.path)/${_config}
    export _SHRENDD_CONFIG_TEMPLATE_PATH="$(shrenddOrDefault "shrendd.config.definition")"
    if [ "$(shrenddOrDefault "shrendd.config.validate")" == "true" ]; then
      echo "validating shrend definition..."
      if [ -f "$(shrenddOrDefault "shrendd.config.definition")" ]; then
        export _SHRENDD_CONFIG=$(cat "$(shrenddOrDefault "shrendd.config.definition")")
      else
        VAR="$(shrenddOrDefault "shrendd.config.definition")"
        DIR="."
        if [[ "$VAR" == *"/"* ]]; then
          DIR=${VAR%/*}
          if [ -d $DIR ]; then
            :
          else
            mkdir -p $DIR
          fi
        fi
        echo "" > "$VAR"
        export _SHRENDD_CONFIG=""
      fi
    else
      echo "shrendd proper"
      if [ -f "$_config_path_proper" ]; then
        export _SHRENDD_CONFIG=$(cat $_config_path_proper)
      else
        VAR="$_config_path_proper"
        DIR="."
        if [[ "$VAR" == *"/"* ]]; then
          DIR=${VAR%/*}
          if [ -d $DIR ]; then
            :
          else
            mkdir -p $DIR
          fi
        fi
        echo "" > "$VAR"
        export _SHRENDD_CONFIG=""
      fi
    fi
    echo "provided config"
    if [ -f "$_config_path_proper" ]; then
      export _PROVIDED_CONFIG=$(cat $_config_path_proper)
    else
      VAR="$_config_path_proper"
      DIR="."
      if [[ "$VAR" == *"/"* ]]; then
        DIR=${VAR%/*}
        if [ -d $DIR ]; then
          :
        else
          mkdir -p $DIR
        fi
      fi
      echo "" > "$VAR"
      export _PROVIDED_CONFIG=""
    fi
  fi
  export _reconfigured="false"
  export _STARTING_DIR=$(pwd)
  export _IGNORE_REQUIRED="false"

  if [ "$SHRENDD_EXTRACT" == "true" ] || [ -n "$SHRENDD_SPAWN" ]; then
    doTemplate
  fi

  export _IGNORE_REQUIRED="false"
  if [[ "$deploy_action" != "skip" ]]; then
    initConfig
    for _specific_module in $_module; do
      loadConfig $_specific_module
      echo "switching to module: $_the_module"
      cd $_the_module
      export _MODULE_DIR=$(pwd)
      export _SHRENDD_DEPLOY_DIRECTORY=$(shrenddOrDefault "shrendd.deploy.dir")
      echo "shrendd deploy dir: $_SHRENDD_DEPLOY_DIRECTORY"
      echo "trying to load array of targets for: $_MODULE_DIR"
      initTargets
      moduleRender $_specific_module
      unwindConfig
      cd $_STARTING_DIR
    done
  fi
}
