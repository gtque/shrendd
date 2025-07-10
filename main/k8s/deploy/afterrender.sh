#!/bin/bash
set -euo pipefail

export OBJECT_LIST=""
export COMMA=""

function preserveObjects {
  echo "Preserving tear down process."
  echo "Preserving templates from: $RENDER_DIR"
  export APP_K8S_OBJECTS=""
  files=$(ls $RENDER_DIR | sed -e "s/  /,/g" | grep [0-9].*.yml || echo "shrendd: no files found")
  if [ "$files" == "shrendd: no files found" ]; then
    echo "no files found"
  else
    files=$(echo "$files" | sed -e "s/[0-9].[-_]//g" | sed -e "s/.yml//g" | sed -e "s/.json.srd//g" | sed -e "s/-.*//g")
    echo -n "files to preserve: $files"
    for entry in $files
    do
      if [[ "$OBJECT_LIST" != *"$entry"* ]]; then
        export OBJECT_LIST="$OBJECT_LIST$COMMA$entry"
        export COMMA=","
      fi
    done
    echo "List of template objects: $OBJECT_LIST"
    export APP_K8S_OBJECTS="\"$OBJECT_LIST\""
  fi
}

process_k8s_script_maps() {
  FILES_TEMPLATE_DIR=$TEMPLATE_DIR/$1
  if [ -d $FILES_TEMPLATE_DIR ]; then
    echo "Adding scripts to configmaps..."
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
      echo -e "======================================================\nprocessing scripts for $fname"
      cd $fname
      #sed -e "s/^/  /g"
      _replace_path=$(echo "$TEMPLATE_DIR/" | sed -e 's/\//\\\//g' )
      echo "replacement: $_replace_path"
      _target_render_dir=$(echo "$fname" | sed -e "s/${_replace_path}//g" )
      echo "target render dir: $_target_render_dir"
#      doRender "$fname"
      #ansible-playbook $SHRENDD_DIR/render/ansible/site.yml -i hosts -e "template_output_dir=$RENDER_DIR" -e "template_input_dir=$fname" -e @$_config -e "playbook_operations=render" --extra-vars "app_k8s_objects=$OBJECT_LIST" -D
      config_maps="*.srd"
      script_files="*.sh"
      _target_render_dir="$RENDER_DIR/temp/$_target_render_dir"
      if [ -d $_target_render_dir ]; then
        :
      else
        mkdir -p "$_target_render_dir"
      fi
      for config_map in $config_maps
      do
        echo "  templating: $config_map"
        _CM_FILE=$(basename "$config_map" | sed 's/.srd//')
        cp "$config_map" "$_target_render_dir/$config_map"
        for sname in $script_files
        do
          if [ "$sname" == "*.sh" ]; then
            echo "no scripts found, nothing to append to config map..."
          else
            _FILE=$(basename "$sname")
            echo "    adding $_FILE: $_CM_FILE"
            export _text=$(cat "$sname")
            echo "    configified..."
#            _yq=$(yq --null-input ".data.[\"$_FILE\"] += strenv(_text)")
#            echo -e "configured script:\n$_yq"
#            cp $_target_render_dir/$config_map $_target_render_dir/$config_map
#            cat $_target_render_dir/$config_map
            echo -e "\ntrying to just load yaml..."
#            yq -i "." $_target_render_dir/$config_map
            echo "now to do the place holder..."
            yq -i ".data.shrendd_place_holder = \"doh!\"" $_target_render_dir/$config_map
            echo "    place holder placed"
#            _yq_rendered=$(echo "$_yq" | yq ea '. as $item ireduce ({}; . * $item )' - $_target_render_dir/$config_map)
            yq -i ".data.[\"$_FILE\"] += strenv(_text)" $_target_render_dir/$config_map
#            echo -e "rendered script:\n$_yq_rendered"
#            echo -e "$_yq_rendered" > $_target_render_dir/$config_map
            yq -i "del(.data.shrendd_place_holder)" $_target_render_dir/$config_map
#              echo "  $_FILE: |" >> $RENDER_DIR/temp/scripts/$fname/$config_map
#              echo "$(echo -e -n "$(cat $sname | sed 's/^/    /')")" >> $RENDER_DIR/temp/scripts/$fname/$config_map
          fi
        done
      done
      doRender "$_target_render_dir"
      echo -e "${_TEXT_PASS}+++++++++++++++rendered $fname+++++++++++++++"
      cat $RENDER_DIR/$_CM_FILE
      echo -e "+++++++++++++++rendered $fname+++++++++++++++${_CLEAR_TEXT_COLOR}"
      echo -e "finished processing scripts for $fname\n======================================================"
      cd $_curdir
    done
    shrenddLog "k8s/afterrender: process_k8s_script_maps: rm ${RENDER_DIR}/temp/scripts"
    rm -rf "$RENDER_DIR/temp/scripts"
    sleep 1
  fi
}

echo "processing configmap scripts"
process_k8s_script_maps "scripts" 1
preserveObjects
echo "processing teardown scripts"
if [[ "$APP_K8S_OBJECTS" != *"configmap"* ]] && [[ -n "$APP_K8S_OBJECTS" ]]; then
  export APP_K8S_OBJECTS="$APP_K8S_OBJECTS${COMMA}configmap"
fi
process_k8s_script_maps "teardown" 0
echo "the k8s objects: \"$APP_K8S_OBJECTS\""