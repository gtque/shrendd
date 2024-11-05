#!/bin/bash
set -euo pipefail

export OBJECT_LIST=""
export COMMA=""
echo "Preserving tear down process."
echo "Preserving templates from: $TEMPLATE_DIR"
export files=$(ls $TEMPLATE_DIR | sed -e "s/  /,/g" | grep [0-9].*.j2 | sed -e "s/[0-9].[-_]//g" | sed -e "s/.yml.j2//g" | sed -e "s/.json.j2//g" | sed -e "s/-.*//g")
for entry in $files
do
  export OBJECT_LIST="$OBJECT_LIST$COMMA$entry"
  export COMMA=","
done
echo "List of template objects: $OBJECT_LIST"

process_script_maps() {
  FILES_TEMPLATE_DIR=$TEMPLATE_DIR/$1
  if [ -d $FILES_TEMPLATE_DIR ]; then
    echo "Adding scripts to configmap...\n"
    echo "files directory: $FILES_TEMPLATE_DIR"
    config_files="$FILES_TEMPLATE_DIR"
    if [ "$2" -gt 0 ]; then
      config_files="$config_files/*"
    fi
    echo "files should be in: $config_files"
    for fname in $config_files
    do
      file_dir=$fname
      echo "processing: $fname"
      ansible-playbook $SHRENDD_WORKING_DIR/.shrendd/render/ansible/site.yml -i hosts -e "template_output_dir=$RENDER_DIR" -e "template_input_dir=$fname" -e @$_config -e "playbook_operations=render" --extra-vars "app_k8s_objects=$OBJECT_LIST" -D
      config_maps="$fname/*.j2"
      script_files="$fname/*.sh"
      for config_map in $config_maps
      do
        echo "  templating: $config_map"
          for sname in $script_files
          do
            _FILE=$(basename "$sname")
            _CM_FILE=$(basename "$config_map" | sed 's/.j2//')
            echo "    replacing $_FILE: $_CM_FILE"
            echo "  $_FILE: |" >> $RENDER_DIR/$_CM_FILE
            echo "$(echo -e -n "$(cat $sname | sed 's/^/    /')")" >> $RENDER_DIR/$_CM_FILE
          done
      done
    done
    sleep 1
  fi
}

process_script_maps "teardown" 0
process_script_maps "scripts" 1