#!/bin/bash
set -euo pipefail

source "$SHRENDD_DIR/render/deploy.sh"
source "$SHRENDD_DIR/k8s/deploy/beforerender.sh"
#export TEMPLATE_DIR="$_MODULE_DIR/deploy/k8s/templates"
#export RENDER_DIR="$_MODULE_DIR/deploy/k8s/rendered"