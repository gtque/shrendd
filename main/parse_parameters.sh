#!/bin/bash

module=${module:-}
config=${config:-}
is_debug=${is_debug:-true}
_offline=${_offline:-false}
stub=${stub:-false}
deployaction=${deployaction:-$(shrenddOrDefault "shrendd.default.action")}
spawn=${spawn:-}

export FORCE_SHRENDD_UPDATES="false"
export LOG_VERBOSE="false"
export SKIP_TEMPLATE=false
export SKIP_STANDARD=false
export SKIP_DEPLOY="false"
export SKIP_RENDER="false"
export SHRENDD_EXTRACT="false"
export _requested_help="false"
export _strict="false"
export _JUST_INITIALIZE="false"
_do_something=""

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    if [[ "$param" == "module" ]]; then
      declare $param="${!param}$2 "
      shift
    elif [[ "$param" == "build" ]]; then
      export SKIP_DEPLOY="true"
      export SKIP_RENDER="true"
      _do_something="true"
    else
      echo "=>setting $param=\"$2\""
      declare $param="$2"
      shift
    fi
  elif [[ $1 == "-init" ]]; then
    export _JUST_INITIALIZE="true"
  elif [[ $1 == "-offline" ]]; then
    param="_offline"
    declare $param="true"
  elif [[ $1 == "-verbose" ]]; then
      export LOG_VERBOSE="true"
  elif [[ $1 == "-debug" ]]; then
    param="is_debug"
    declare $param="true"
  elif [[ $1 == "-live" ]]; then
    param="is_debug"
    declare $param="false"
  elif [[ $1 == "-share" ]]; then
    export SHRENDD_CONFIG_UNWIND="false"
  elif [[ $1 == "-extract" ]]; then
    export SHRENDD_EXTRACT="true"
  elif [[ $1 == "-S" ]]; then
    export _strict="true"
  elif [[ $1 == "-d" ]]; then
    param="deployaction"
    declare $param="deploy"
    _do_something="true"
  elif [[ $1 == "-t" ]]; then
    param="deployaction"
    declare $param="teardown"
    _do_something="true"
  elif [[ $1 == "-b" ]]; then
    export SKIP_DEPLOY="true"
    export SKIP_RENDER="true"
    _do_something="true"
  elif [[ $1 == "-r" ]]; then
    export SKIP_DEPLOY="true"
    _do_something="true"
  elif [[ $1 == "-U" ]]; then
    export FORCE_SHRENDD_UPDATES="true"
  elif [[ $1 == "?" ]]; then
    export helped=true
    echo "Usage:"
    echo -e "  -init\n\t  initialize shrendd by downloading render and specified modules. Skips all other actions regardless of other flags."
    echo -e "  -debug\n\t  run as local debug deployment/teardown, preserves rendered templates, this is the default mode"
    echo -e "  -live\n\t  run as live deployment/teardown, including auto clean up of rendered templates."
    echo -e "  -share\n\t  preserve config between modules, even with custom config, ie no unwinding.\n\t You can also set 'shrendd.config.unwind: false' in the shrendd.yml file."
    echo -e "  -extract\n\t  produce a config-template.yml file from template files. This only considers those referenced in \${} or \$(getConfig) declarations"
    echo -e "  -offline\n\t  Run in offline mode. Will not attempt to download shrendd, modules, libraries, or plugins. This always sets force update to false."
    echo -e "  -verbose\n\t  Enables verbose logging. Because of the way evaluated expressions are returned, verbose logging will be logged to  $_DEPLOY_ERROR_DIR/shrendd.log."
    echo -e "  --spawn [config yaml file name]\n\t generate a config yaml file based existing config-template.yml file."
    echo -e "  --stub [deployment type to stub]\n\t  stub some default template definitions, if defined, for the specified deployment type.\n\t  if stub is specified, render will be skipped, regardless of the order of parameters specified when running shrendd.\nt\t  example: --stub k8s"
    echo -e "  --module [relative\\path\\\to\\module]\n\t  the path to the module to be deployed, defaults to current directory.\n\t example: --module infrastructure\n\t example: --module simpleApiServer"
    echo -e "  --config [relative\\path\\\to\\\config.yml]\n\t  the path to the config.yml file to use for the deployment, relative to the configured config path (shrendd.config.path which defaults to './config').\n\t  default value: localdev.yml"
    echo -e "  --deployaction [deploy|teardown|render]\n\t  the deployment action being performed, deploy to render and deploy, teardown to uninstall or delete the deployment, defaults to render only.\n\t  The last specified deploy action will be respected, this includes any short hand action parameters specified."
    echo -e "  -b, --build\n\t  build the templates without rendering them.\n\t    This is particularly useful if using libraries and importing templates."
    echo -e "  -d\n\t  deploy as the deployment action, short hand for --deployaction deploy\n\t    you may specify this and -t, but the last one specified wins and will determine the deployment action."
    echo -e "  -t\n\t  teardown as the deployment action, short hand for --deployaction teardown\n\t    you may specify this and -s, but the last one specified wins and will determine the deployment action."
    echo -e "  -r\n\t  render only, skip deploy/teardown"
    echo -e "  -S\n\t  strict mode, fail on warnings"
    echo -e "  -U\n\t  update libraries"
    export _requested_help="true"
  fi
  shift
done


export _stub=$stub
if [ -z "$module" ]; then
  module="."
fi
export _module=$module
if [[ $config == "" ]]; then
  export config=$(shrenddOrDefault shrendd.config.default)
fi
export _config=$config
export _is_debug=$is_debug
if [ "$_do_something" == "true" ]; then
  :
else
  if [ "$SHRENDD_EXTRACT" == "true" ] || [ -n "$spawn" ]; then
    deployaction="skip"
  fi
fi
echo "action: $deployaction"
if [ "$deployaction" == "render" ]; then
  deployaction="deploy"
  export SKIP_DEPLOY="true"
fi
if [[ "${_offline}" == "true" ]]; then
  export FORCE_SHRENDD_UPDATES="false"
fi
export is_offline="${_offline}"
export deploy_action=${deployaction}
export SHRENDD_SPAWN="$spawn"