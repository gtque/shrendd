#!/bin/bash
set -euo pipefail

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

process_script_maps() {
  FILES_TEMPLATE_DIR=$TEMPLATE_DIR/$1
  if [ -d $FILES_TEMPLATE_DIR ]; then
    echo "Adding scripts to configmap..."
    echo "files directory: $FILES_TEMPLATE_DIR"
    config_files="$FILES_TEMPLATE_DIR"
    if [ "$2" -gt 0 ]; then
      config_files="$config_files/*"
    fi
    echo "files should be in: $config_files"
    _curdir=$(pwd)
    for fname in $config_files
    do
      file_dir=$fname
      echo "processing: $fname"
      cd $fname
      doRender "$fname"
      #ansible-playbook $SHRENDD_WORKING_DIR/.shrendd/render/ansible/site.yml -i hosts -e "template_output_dir=$RENDER_DIR" -e "template_input_dir=$fname" -e @$_config -e "playbook_operations=render" --extra-vars "app_k8s_objects=$OBJECT_LIST" -D
      config_maps="*.srd"
      script_files="*.sh"
      for config_map in $config_maps
      do
        echo "  templating: $config_map"
          for sname in $script_files
          do
            _FILE=$(basename "$sname")
            _CM_FILE=$(basename "$config_map" | sed 's/.srd//')
            echo "    replacing $_FILE: $_CM_FILE"
            echo "  $_FILE: |" >> $RENDER_DIR/$_CM_FILE
            echo "$(echo -e -n "$(cat $sname | sed 's/^/    /')")" >> $RENDER_DIR/$_CM_FILE
          done
      done
      cd $_curdir
    done
    sleep 1
  fi
}

process_script_maps "teardown" 0
process_script_maps "scripts" 1