#!/bin/bash
set -euo pipefail

printf "always do 00 first.\n"
printf "Dry running install...\n"
kubectl --v=0 apply --dry-run=server -f $RENDER_DIR/00*
sleep 1

printf "Dry run succeeded.\nInstalling manifests for 00 objects...\n"
kubectl --v=1 apply --server-side -f $RENDER_DIR/00*
sleep 1

printf "Dry running install...\n"
kubectl --v=0 apply --dry-run=server -f $RENDER_DIR
sleep 1

printf "Dry run succeeded.\nInstalling manifests...\n"
kubectl --v=1 apply --server-side -f $RENDER_DIR
sleep 1