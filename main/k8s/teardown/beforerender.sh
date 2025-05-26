#!/bin/bash
set -euo pipefail

source $SHRENDD_WORKING_DIR/.shrendd/render/deploy.sh
source $SHRENDD_WORKING_DIR/.shrendd/k8s/deploy/beforerender.sh
#export TEMPLATE_DIR="$_MODULE_DIR/deploy/k8s/templates"
#export RENDER_DIR="$_MODULE_DIR/deploy/k8s/rendered"