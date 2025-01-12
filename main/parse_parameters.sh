#!/bin/bash

module=${module:-.}
config=${config:-notset}
is_debug=${is_debug:-true}
stub=${stub:-false}
deployaction=${deployaction:-setup}

export SKIP_TEMPLATE=false
export SKIP_STANDARD=false
export SKIP_DEPLOY="false"
export _requested_help="false"
export _strict="false"

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
    shift
  elif [[ $1 == "-debug" ]]; then
    param="is_debug"
    declare $param="true"
  elif [[ $1 == "-live" ]]; then
    param="is_debug"
    declare $param="false"
  elif [[ $1 == "-S" ]]; then
    export _strict="true"
  elif [[ $1 == "-s" ]]; then
    param="deployaction"
    declare $param="setup"
  elif [[ $1 == "-t" ]]; then
    param="deployaction"
    declare $param="teardown"
  elif [[ $1 == "-r" ]]; then
    export SKIP_DEPLOY="true"
  elif [[ $1 == "?" ]]; then
    export helped=true
    echo "Usage:"
    echo -e "  -debug\n\t  run as local debug deployment/teardown, preserves rendered templates, this is the default mode"
    echo -e "  -live\n\t  run as live deployment/teardown, including auto clean up of rendered templates."
    echo -e "  --stub [deployment type to stub]\n\t  stub some default template definitions, if defined, for the specified deployment type.\n\t  if stub is specified, render will be skipped, regardless of the order of parameters specified when running shrendd.\nt\t  example: --stub k8s"
    echo -e "  --module [relative\\path\\\to\\module]\n\t  the path to the module to be deployed, defaults to current directory.\n\t example: --module infrastructure\n\t example: --module simpleApiServer"
    echo -e "  --config [relative\\path\\\to\\\config.yml]\n\t  the path to the config.yml file to use for the deployment, relative to the configured config path (shrendd.config.path which defaults to './config').\n\t  default value: localdev.yml"
    echo -e "  --deployaction [setup|teardown]\n\t  the deployment action being performed, setup to render and deploy, teardown to uninstall or delete the deployment, defaults to setup"
    echo -e "  -s\n\t  setup as the deployment action, short hand for --deployaction setup\n\t    you may specify this and -t, but the last one specified wins and will determine the deployment action."
    echo -e "  -t\n\t  teardown as the deployment action, short hand for --deployaction teardown\n\t    you may specify this and -s, but the last one specified wins and will determine the deployment action."
    echo -e "  -r\n\t  render only, skip deploy"
    echo -e "  -S\n\t  strict mode, fail on warnings"
    export _requested_help="true"
  fi
  shift
done


export _stub=$stub
export _module=$module
if [[ $config == "notset" ]]; then
  export config=$(shrenddOrDefault shrendd.config.default)
fi
export _config=$config
export _is_debug=$is_debug
export deploy_action=${deployaction}