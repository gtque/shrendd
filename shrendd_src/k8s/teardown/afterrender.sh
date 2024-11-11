#!/bin/bash

#get undeploy from undeploy config map...
export OBJECT_LIST=""
export COMMA=""

echo "Preserving tear down process."
echo "Preserving templates from: $TEMPLATE_DIR"
export files=$(ls $TEMPLATE_DIR | sed -e "s/  /,/g" | grep [0-9].*.srd | sed -e "s/[0-9].[-_]//g" | sed -e "s/.yml.srd//g" | sed -e "s/.json.srd//g" | sed -e "s/-.*//g")
for entry in $files
do
  export OBJECT_LIST="$OBJECT_LIST$COMMA$entry"
  export COMMA=","
done
echo "List of template objects: $OBJECT_LIST"
export APP_K8S_OBJECTS="$OBJECT_LIST"

_curdir=$(pwd)
cd $TEMPLATE_DIR/teardown
doRender "$TEMPLATE_DIR/teardown"
cd $_curdir
#ansible-playbook $SHRENDD_WORKING_DIR/.shrendd/render/ansible/site.yml -i hosts -e "template_output_dir=$RENDER_DIR" -e "template_input_dir=$TEMPLATE_DIR/teardown" -e @$_config -e "playbook_operations=render" --extra-vars "app_k8s_objects=$OBJECT_LIST" -D

export TEARDOWN_NAMESPACE=$(yq e '.metadata.namespace' $RENDER_DIR/01_configmap-teardown.yml)
export TEARDOWN_NAME=$(yq e '.metadata.name' $RENDER_DIR/01_configmap-teardown.yml)
export TEARDOWN_PARTOF=$(yq e '.metadata.labels."app.kubernetes.io/part-of"' $RENDER_DIR/01_configmap-teardown.yml)

echo "namespace: $TEARDOWN_NAMESPACE"
echo "name: $TEARDOWN_NAME"
