#!/bin/bash

module=${module:-.}
config=${config:-config/config-localdev.yml}
is_debug=${is_debug:-true}
deployaction=${deployaction:-setup}

export SKIP_TEMPLATE=false
export SKIP_STANDARD=false
export SKIP_DEPLOY="false"
export _requested_help="false"
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
    echo -e "  --module [relative\\path\\\to\\module]\n\t  the path to the module to be deployed\n\t example: --module infrastructure\n\t example: --module simpleApiServer"
    echo -e "  --language [language\\type]\n\t  the path to the language type, java|k8s|go etc...\n\t example: --language k8s\n\t example: --language java"
    echo -e "  --config [relative\\path\\\to\\\config.yml]\n\t  the path to the config.yml file to use for the deployment."
    echo -e "  --deployaction [setup|teardown]\n\t  the deployment action being performed, setup to render and deploy, teardown to uninstall or delete the deployment"
    echo -e "  -s\n\t  setup as the deployment action, short hand for --deployaction setup\n\t    you may specify this and -t, but the last one specified wins and will determine the deployment action."
    echo -e "  -t\n\t  teardown as the deployment action, short hand for --deployaction teardown\n\t    you may specify this and -s, but the last one specified wins and will determine the deployment action."
    echo -e "  -r\n\t  render only, skip deploy"
    export _requested_help="true"
  fi
  shift
done

export _module=$module
export _config=$config
export _is_debug=$is_debug
export deploy_action=${deployaction}