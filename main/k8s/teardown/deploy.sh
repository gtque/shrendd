#!/bin/bash
set -euo pipefail

export TEARDOWN_DATA=$(kubectl -n $TEARDOWN_NAMESPACE get configmap $TEARDOWN_NAME -o yaml)
shrenddEchoIfNotSilent "$TEARDOWN_DATA"
export TEARDOWN_PRE=$(printf "$TEARDOWN_DATA" | yq e '.data."pre.sh"' -)
export TEARDOWN_STANDARD=$(printf "$TEARDOWN_DATA" | yq e '.data.standard' -)
export TEARDOWN_POST=$(printf "$TEARDOWN_DATA" | yq e '.data."post.sh"' -)
export SKIP_STANDARD_TEARDOWN=false

if [ -z "$TEARDOWN_PRE" ] || [ "$TEARDOWN_PRE" == "null" ]; then
  shrenddEchoIfNotSilent "no pre.sh tear down found."
else
  shrenddEchoIfNotSilent "running pre.sh tear down: $RENDER_DIR/pre.sh"
  echo "$TEARDOWN_PRE" > "$RENDER_DIR/pre.sh"
  chmod 777  "$RENDER_DIR"/*.sh
  source "$RENDER_DIR/pre.sh"
fi

if [ "$SKIP_STANDARD_TEARDOWN" == "false" ]; then
  echo "running standard tear down. $TEARDOWN_NAMESPACE delete $TEARDOWN_STANDARD $_TEARDOWN_IDENTIFIER"
  kubectl --v=0 -n $TEARDOWN_NAMESPACE delete $TEARDOWN_STANDARD $_TEARDOWN_IDENTIFIER
else
  echo "skipping standard tear down"
fi

if [ -z "$TEARDOWN_POST" ] || [ "$TEARDOWN_POST" == "null" ]; then
  shrenddEchoIfNotSilent "no post.sh tear down found."
else
  shrenddEchoIfNotSilent "running post.sh tear down: $RENDER_DIR/post.sh"
  echo -e "$TEARDOWN_POST" > "$RENDER_DIR/post.sh"
  chmod 777  "$RENDER_DIR"/*.sh
  source "$RENDER_DIR/post.sh"
fi
#kubectl --v=$KUBECTL_VERBOSITY -n $NAMESPACE delete $OBJECT_LIST -l app.kubernetes.io/name=$NAME
#if custom undeploy script is present, parse it out of the configmap and then run it

#_pv=$(kubectl -n eangeli get pvc minecraft-jujutsu1 -o yaml | yq e '.spec.volumeName' -)
#echo "deleting the job"
#kubectl -n eangeli delete deployment minecraft-jujutsu1
#echo "pod deleted, deleting the pvc"
#kubectl -n eangeli delete pvc minecraft-jujutsu1
#echo "pvc deleted, will try to delete the private volume: $_pv"
#kubectl delete pv $_pv --grace-period=0 --force &
#echo "force finalizers to null..."
#kubectl patch pv $_pv -p '{"metadata":{"finalizers":null}}'
#echo "everything should be deleted..."
#kubectl -n eangeli get pod
#kubectl -n eangeli get pvc
#kubectl get pv
