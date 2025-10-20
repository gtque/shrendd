#!/bin/bash

function templateFileScanner {
  _already_found="not found"
  _check_config_path="$(shrenddOrDefault "shrendd.config.path" | sed -e "s/\.\//\//g")"
  _check_config_path_src="$(shrenddOrDefault "shrendd.config.src" | sed -e "s/\.\//\//g")"
  while IFS= read -r fname; do
    fname_q="$(echo "$(pwd)$fname" | sed "s/\.\//\//g")"
    if [[ "$fname" != *"$_check_config_path"* ]] || [[ "$fname" == *"$_check_config_path_src"* ]]; then
      if [ "$_files_extracted" != *"$fname_q "* ] && [ "$fname" != "*.srd" ]; then
        _files_extracted="$(echo "$_files_extracted $(pwd)$fname" | sed "s/\.\//\//g")"
        shrenddEchoIfNotSilent "templateFileScanner: extracting $fname>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        if [[ "$fname" == *".sh" ]] || [[ "$fname" == *".sh.srd" ]]; then
          _template=$(cat "$fname")
        else
          _template=$(configify "$fname")
        fi
        shrenddEchoIfNotSilent "getConfig"
        _scanner="$(echo "$_template" | grep -o "\$(getConfig [^)]*)" || echo "not found")"
        while IFS= read -r match; do
          # Your action here, using the $match variable
          if [ "$match" != "not found" ]; then
            count=$(echo "$match" | grep -o "getConfig" | wc -l)
            match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty//g" | sed -e "s/\\\$(getConfig//g" | sed -e "s/)//g" | sed -e "s/\\\//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
            shrenddEchoIfNotSilent "  Found: $match"
            if [ "$count" -gt 1 ]; then
              shrenddEchoIfNotSilent "    nested reference found";
              shrenddEchoIfNotSilent "nested reference found: $match ($fname)-> cannot full extract, please add any indirectly referenced configs to the template." >> "$_DEPLOY_ERROR_DIR/render_warning.log"
            fi
            _already_found=$(echo " $_checker " | grep " $match " || echo "not found")
            if [ "$_already_found" != "not found" ]; then
              shrenddEchoIfNotSilent "   already found..:$match"
            else
              export _checker="$(echo "$_checker\n $match ")"
              shrenddEchoIfNotSilent "   not found, adding to list"
            fi
          fi
        done <<< "$_scanner"
        shrenddEchoIfNotSilent "getConfigOrEmpty:"
        _scanner="$(echo "$_template" | grep -o "\$(getConfigOrEmpty [^)]*)" || echo "not found")"
    #         echo "$_scanner" | while read match; do
        while IFS= read -r match; do
          # Your action here, using the $match variable
          if [ "$match" != "not found" ]; then
            count=$(echo "$match" | grep -o "getConfig" | wc -l)
            match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty//g" | sed -e "s/\\\$(getConfig//g" | sed -e "s/)//g" | sed -e "s/\\\//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
            shrenddEchoIfNotSilent "  Found: $match"
            if [ "$count" -gt 1 ]; then
              shrenddEchoIfNotSilent "    nested reference found";
              ecshrenddEchoIfNotSilentho "nested reference found: $match ($fname)-> cannot full extract, please add any indirectly referenced configs to the template." >> "$_DEPLOY_ERROR_DIR/render_warning.log"
            fi
            _already_found=$(echo "$_checker" | grep "\n *$match *\n" || echo "not found")
            if [ "$_already_found" != "not found" ]; then
              shrenddEchoIfNotSilent "   already found..>\"$_checker\" | grep \"$match\""
            else
              export _checker="$(echo "$_checker\n$match")"
              shrenddEchoIfNotSilent "   not found, adding to list"
            fi
          fi
        done <<< "$_scanner"
        _scanner_imports="$(echo "$_template" | grep -o "\$(importShrendd [^)]*)" || echo "not found")"
        while IFS= read -r match; do
          # Your action here, using the $match variable
          if [[ "$match" != "not found" ]] && [[ "$match" != *":plugin"* ]]; then
            _import=$(echo "$match" | sed -e "s/\\\$(importShrendd //g" | sed -e "s/)//g" | sed -e "s/\"//g" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
            shrenddEchoIfNotSilent "  found import: $_import"
            if [ "$_already_found" != "not found" ]; then
              shrenddEchoIfNotSilent "   already extracted..:$match"
            else
              export _files_extracted="$(echo "$_files_extracted $match")"
              shrenddEchoIfNotSilent "   not extracted, adding to list"
            fi
            templateFileScanner "$(importShrendd "$_import" "extract")"
            shrenddEchoIfNotSilent "  import processed..."
  #          _template=$(cat $fname | sed -e "s/\\\${\([^}]*\)}/\\\$(getConfig \"\1\")/g")
          else
            if [[ "$match" == *":plugin"* ]]; then
              shrenddEchoIfNotSilent "  extracting plugin not full supported, assumes scripts are extracted separately, skipping plugin import: $match"
            else
              shrenddEchoIfNotSilent "  no import found."
            fi
          fi
        done <<< "$_scanner_imports"
        shrenddEchoIfNotSilent "templateFileScanner: end $fname<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      fi
    fi
  done <<< "$1"
}

#need to figure out how/what other files beyond the template files need to be scanned
#for the extract
function extractTemplate {
  shrenddEchoIfNotSilent "$_TEXT_WARN{{{{temp extraction started}}}}${_CLEAR_TEXT_COLOR}"
  _template_path="${_SHRENDD_CONFIG_TEMPLATE_PATH}.temp"
  shrenddEchoIfNotSilent "config template path: $_SHRENDD_CONFIG_TEMPLATE_PATH"
  if [ -f "$_template_path" ]; then
    :
  else
    VAR="$_template_path"
    DIR="."
    if [[ "$VAR" == *"/"* ]]; then
      DIR=${VAR%/*}
      if [ -d "$DIR" ]; then
        :
      else
        mkdir -p "$DIR"
      fi
    fi
    echo "" > "$_template_path"
  fi
  _actual_template_path="$(pwd)"
  if [[ "$_template_path" == "$_actual_template_path"* ]]; then
    shrenddEchoIfNotSilent "just using template path"
    _actual_template_path="$_template_path"
  else
    shrenddEchoIfNotSilent "adding template path"
    _actual_template_path=$(echo "$_actual_template_path/$_template_path" | sed -e "s/\/\.\//\//g")
  fi
  shrenddEchoIfNotSilent "path: $_actual_template_path"
  export _template_stub=$(cat "$_STARTING_DIR/.shrendd/render/config/template.yml")
  _current_template=""
  export _checker=""
  _curdir=$(pwd)
  _files_extracted=""
  if [ -d "$_SHRENDD_DEPLOY_DIRECTORY" ]; then
    shrenddEchoIfNotSilent "${_TEXT_INFO}found deploy directory, extracting from: $_SHRENDD_DEPLOY_DIRECTORY${_CLEAR_TEXT_COLOR}"
    cd "$_SHRENDD_DEPLOY_DIRECTORY"
    _deploy_files=$(find "$(pwd -P)" -type f -name "*.sh" -print)
    shrenddEchoIfNotSilent "non-srd files: $_deploy_files"
    if [[ -n "$_deploy_files" ]]; then
      templateFileScanner "$_deploy_files"
    fi
#    templateFileScanner "$_deploy_files"
    cd "$_curdir"
  fi
  if [ -d "$(shrenddOrDefault "shrendd.config.src")" ]; then
    shrenddEchoIfNotSilent "${_TEXT_INFO}found config src directory, extracting from: $(shrenddOrDefault "shrendd.config.src")${_CLEAR_TEXT_COLOR}"
    _deploy_files=$(find "$(shrenddOrDefault "shrendd.config.src")" -type f -print)
    templateFileScanner "$_deploy_files"
    cd "$_curdir"
  fi
  shrenddEchoIfNotSilent "$_TEXT_WARN{{{{temp extraction checking targets}}}}${_CLEAR_TEXT_COLOR}"
  for _target in $targets; do
    export target="$_target"
    shrenddEchoIfNotSilent "extracting: $target"
    shrenddEchoIfNotSilent "initializing target template directory"
    targetDirs "$target"
    if [[ -d "$TEMPLATE_DIR" ]]; then
      _curdir="$(pwd)"
      shrenddEchoIfNotSilent "running bash templating..."
      cd "$TEMPLATE_DIR"
#      config_files="*/*.srd"
      config_files=$(find "." -type f -name "*.srd" -print)
      shrenddEchoIfNotSilent "files should be in: $config_files"
      for fname in $config_files; do
        shrenddLog "extractTemplate: reset error log:rm ${_DEPLOY_ERROR_DIR}/config_error.log"
        rm -rf "$_DEPLOY_ERROR_DIR/config_error.log"
        fname_q="$(echo "$(pwd)$fname" | sed "s/\.\//\//g")"
        if [ "$_files_extracted" != *"$fname_q "* ] && [ "$fname" != "*.srd" ]; then
          _files_extracted="$(echo "$_files_extracted $fname_q")"
          shrenddEchoIfNotSilent "extractTemplate: extracting $fname>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
          _template=$(cat "$fname" | sed -e "s/\\\${\([^}]*\)}/\\\$(getConfig \"\1\")/g")
          shrenddEchoIfNotSilent "getConfig"
          _scanner="$(echo "$_template" | grep -o "\$(getConfig [^)]*)" || echo "not found")"
          while IFS= read -r match; do
            # Your action here, using the $match variable
            if [ "$match" != "not found" ]; then
              count=$(echo "$match" | grep -o "getConfig" | wc -l)
              match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty //g" | sed -e "s/\\\$(getConfig //g" | sed -e "s/)//g" | sed -e "s/\\\//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
              shrenddEchoIfNotSilent "  Found it: $match"
              if [ "$count" -gt 1 ]; then
                shrenddEchoIfNotSilent "    nested reference found";
                shrenddEchoIfNotSilent "nested reference found: $match ($fname)-> cannot full extract, please add any indirectly referenced configs to the template." >> "$_DEPLOY_ERROR_DIR/render_warning.log"
              fi
              _already_found=$(echo "$_checker" | grep "\n *$match *\n" || echo "not found")
              if [ "$_already_found" != "not found" ]; then
                shrenddEchoIfNotSilent "   already found>>>\"$_already_found\":\"$match\""
              else
                export _checker="$(echo "$_checker\n$match")"
                shrenddEchoIfNotSilent "   not found, adding to list"
              fi
            fi
          done <<< "$_scanner"
          shrenddEchoIfNotSilent "getConfigOrEmpty:"
          _scanner="$(echo "$_template" | grep -o "\$(getConfigOrEmpty [^)]*)" || echo "not found")"
  #         echo "$_scanner" | while read match; do
          while IFS= read -r match; do
            # Your action here, using the $match variable
            if [ "$match" != "not found" ]; then
              count=$(echo "$match" | grep -o "getConfig" | wc -l)
              match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty //g" | sed -e "s/\\\$(getConfig //g" | sed -e "s/)//g" | sed -e "s/\\\//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
              shrenddEchoIfNotSilent "  Found: $match"
              if [ "$count" -gt 1 ]; then
                shrenddEchoIfNotSilent "    nested reference found";
                shrenddEchoIfNotSilent "nested reference found: $match ($fname)-> cannot full extract, please add any indirectly referenced configs to the template." >> "$_DEPLOY_ERROR_DIR/render_warning.log"
              fi
              _already_found=$(echo "$_checker" | grep "\n *$match *\n" || echo "not found")
              if [ "$_already_found" != "not found" ]; then
                shrenddEchoIfNotSilent "   already found!!>\"$_checker\" | grep \"$match\""
              else
                export _checker="$(echo "$_checker\n$match")"
                shrenddEchoIfNotSilent "   not found, adding to list"
              fi
            fi
          done <<< "$_scanner"
          _scanner_imports="$(echo "$_template" | grep -o "\$(importShrendd [^)]*)" || echo "not found")"
          while IFS= read -r match; do
            # Your action here, using the $match variable
            if [[ "$match" != "not found" ]] && [[ "$match" != *":plugin"* ]]; then
              _import=$(echo "$match" | sed -e "s/\\\$(importShrendd //g" | sed -e "s/)//g" | sed -e "s/\"//g" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
              shrenddEchoIfNotSilent "  found import: $_import"
              if [ "$_already_found" != "not found" ]; then
                shrenddEchoIfNotSilent "   already extracted..:$match"
              else
                export _files_extracted="$(echo "$_files_extracted $match")"
                shrenddEchoIfNotSilent "   not extracted, adding to list"
              fi
              templateFileScanner "$(importShrendd "$_import" "extract")"
            else
              if [[ "$match" == *":plugin"* ]]; then
                shrenddEchoIfNotSilent "  extracting plugin not fully supported, assumes scripts are extracted separately, skipping plugin import: $match"
              else
                shrenddEchoIfNotSilent "  no import found."
              fi
            fi
          done <<< "$_scanner_imports"
          shrenddEchoIfNotSilent "end $fname<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        else
          shrenddEchoIfNotSilent "already extracted: $fname_q"
        fi
      done
      cd "$_curdir"
    fi
  done
  shrenddEchoIfNotSilent "${_TEXT_INFO}templating the template${_CLEAR_TEXT_COLOR}"
  echo -e "$_checker" | while read match; do
    _o_match="$match"
    match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty//g" | sed -e "s/\\\$(getConfig//g" | sed -e "s/)//g" | sed -e "s/\\\//g" | sed -e "s/\"//g" | sed -e "s/{//g" | sed -e "s/}//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
    match=$(echo "$match" | sed -e 's/\([a-zA-Z0-9 _-]\+ \+[a-zA-Z0-9 _-]\+\)/[\"\1\"]/g')
    if [[ "$match" == *"-"* ]]; then
      :
    else
      match=$(echo "$match" | sed -e "s/_/\./g")
      if [[ "$match" == "."* ]]; then
        shrenddEchoIfNotSilent " starts with a ."
        match=$(echo "$match" | sed -e "s/\./_/")
      fi
#      :
    fi
    match=$(echo "$match" | sed -e "s/\\\$./\\\$/g")
    if [ -n "$match" ]; then
      shrenddEchoIfNotSilent "  extracted: $_o_match => $match"  # Example: Print the match
      _found="empty"
      _current_template_yaml=$(cat "$_actual_template_path")
      if [ -z "$_current_template_yaml" ]; then
        shrenddEchoIfNotSilent "    template is empty: $_actual_template_path"
      else
        shrenddEchoIfNotSilent "    template is not empty"
        _found=$(cat "$_actual_template_path" | yq e ".$match" -)
      fi
      if [ "$_found" ==  "null" ]; then
        shrenddEchoIfNotSilent "    adding to template."
        yq -i ".$match = strenv(_template_stub)" "$_actual_template_path"
      else
        if [ "$_found" == "empty" ]; then
          shrenddEchoIfNotSilent "    creating new template yaml:$match"
          shrenddEchoIfNotSilent "    yq -n \".$match = strenv(_template_stub)\" > $_actual_template_path"
          yq -n ".$match = strenv(_template_stub)" > "$_actual_template_path"
        else
          shrenddEchoIfNotSilent "    already in template."
        fi
      fi
    fi
  done
  shrenddEchoIfNotSilent "${_TEXT_INFO}temp template complete${_CLEAR_TEXT_COLOR}"
}

function extractCleanUp {
  shrenddEchoIfNotSilent "$_TEXT_WARN{{{{extraction started}}}}${_CLEAR_TEXT_COLOR}"
  _template_path="${_SHRENDD_CONFIG_TEMPLATE_PATH}"
  _template_path_temp="${_SHRENDD_CONFIG_TEMPLATE_PATH}.temp"
  if [ -f "$_template_path_temp" ]; then
    if [ -f "$_template_path" ]; then
      :
    else
      VAR="$_template_path"
      DIR="."
      if [[ "$VAR" == *"/"* ]]; then
        DIR=${VAR%/*}
        if [ -d "$DIR" ]; then
          :
        else
          mkdir -p "$DIR"
        fi
      fi
      echo "" > "$_template_path"
    fi
    _actual_template_path="$(pwd)"
#    _actual_template_path=$(echo "$_actual_template_path/$_template_path")
    if [[ "$_template_path" == "$_actual_template_path"* ]]; then
      _actual_template_path="$_template_path"
      _actual_template_path_temp="$_template_path_temp"
    else
      _actual_template_path=$(echo "$_actual_template_path/$_template_path")
      _actual_template_path_temp=$(echo "$(pwd)/$_template_path_temp")
    fi

    shrenddEchoIfNotSilent "temp path: $_actual_template_path_temp"
    export _template_stub=$(cat "$_STARTING_DIR/.shrendd/render/config/template.yml")
    _template_keys=""
    if [ -f "$_actual_template_path" ]; then
      shrenddEchoIfNotSilent "${_TEXT_WARN}template is present${_CLEAR_TEXT_COLOR}"
      _template_keys=$(keysFor "$(cat "$_actual_template_path")")
      _template_keys=" $_template_keys "
      shrenddEchoIfNotSilent "found keys: $_template_keys"
#      echo "current keys: \"$_template_keys\""
    fi
    _template_keys_temp=""
    if [ -f "$_actual_template_path_temp" ]; then
      shrenddEchoIfNotSilent "${_TEXT_WARN}temp template is present $_actual_template_path_temp${_CLEAR_TEXT_COLOR}"
      _template_keys_temp=$(keysFor "$(cat "$_actual_template_path_temp")")
#      echo "current temp keys: \"$_template_keys_temp\""
    fi
    shrenddEchoIfNotSilent "temp keys found:\n$_template_keys_temp"
    for _config_key in $_template_keys_temp; do
      _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
      _yq_name=$(yqName "$_config_key")
      _found="empty"
      shrenddEchoIfNotSilent "${_TEXT_DEBUG}templating:${_CLEAR_TEXT_COLOR} \"$_config_key\"->\"$_yq_name\""
      _has_array="false"
      _drop_key=$(echo "$_config_key" | sed "s/ /$_SPACE_PLACE_HOLDER/g")
      shrenddEchoIfNotSilent "dropping key: \"$_drop_key\""
      _template_keys=$(echo "$_template_keys"| sed "s/ $_drop_key / /g")
#      echo "update keys: $_template_keys"
      if [ -f "$_actual_template_path" ]; then
        _found=$(cat "$_actual_template_path" | yq e ".$_yq_name" -)
      else
        shrenddEchoIfNotSilent "  no template, will try to create it this time."
      fi
      if [ "$_found" ==  "null" ]; then
        shrenddEchoIfNotSilent "  adding to config."
        if [ "$_has_array" == "false" ]; then
          yq -i ".${_yq_name} = strenv(_template_stub)" "$_actual_template_path"
        else
          shrenddEchoIfNotSilent "  trying to add array:\n$_template_stub"
          yq -i ".${_yq_name} = []" "$_actual_template_path"
          yq -i ".${_yq_name} += env(_template_stub)" "$_actual_template_path"
        fi
      else
        if [ "$_found" == "empty" ]; then
          shrenddEchoIfNotSilent "  creating new config yaml:$_yq_name"
          if [ "$_has_array" == "false" ]; then
            yq -n ".${_yq_name} = strenv(_template_stub)" > "$_actual_template_path"
          else
            shrenddEchoIfNotSilent "  trying to add array"
            yq -i ".${_yq_name} = []"  > "$_actual_template_path"
            yq -i ".${_yq_name} += env(_template_stub)" "$_actual_template_path"
          fi
        else
          shrenddEchoIfNotSilent "  already in template."
        fi
      fi
    done
    if [ -f "$_template_path" ]; then
      _template_yaml=$(cat "$_template_path")
      _template_keys=$(echo "$_template_keys" | sed "s/  */ /g")
      shrenddEchoIfNotSilent "${_TEXT_INFO}reducing keys:$_template_keys${_CLEAR_TEXT_COLOR}"
      for _config_key in $_template_keys; do
        shrenddEchoIfNotSilent "  config key: $_config_key"
        _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
        _yq_name=$(yqName "$_config_key")
#        echo "$_template_yaml" | yq e ".$_yq_name" -
        _indirect=$(echo "$_template_yaml" | yq e ".$_yq_name" - | yq e ".indirect" -)
        if [ "$_indirect" != "null" ] && [ "$_indirect" == "true" ]; then
          shrenddEchoIfNotSilent "  indirectly referenced, not dropping: $_yq_name"
        else
          shrenddEchoIfNotSilent "  checking ${_yq_name}"
          if [ "$_yq_name" == "_" ]; then
            shrenddEchoIfNotSilent "  ${_TEXT_WARN}invalid key, if actually present, please manually delete it.${_CLEAR_TEXT_COLOR}"
          else
            shrenddEchoIfNotSilent "  ${_TEXT_WARN}dropping key:${_yq_name} -> $_config_key${_CLEAR_TEXT_COLOR}"
            yq -i "del(.${_yq_name})" "$_actual_template_path"
          fi
          shrenddEchoIfNotSilent "  done with key: ${_yq_name}"
        fi
      done
      shrenddEchoIfNotSilent "attempting to delete empty keys"
      deleteEmptyKeys "$_actual_template_path"
#      yq -i 'del(.. | select(tag == "!!map" and length == 0))' "$_actual_template_path"
#      yq -i 'del(.. | select(length == 0))' "$_actual_template_path"
#      yq -i 'del(.. | select(tag == "!!map" and length == 0))' "$_actual_template_path"
    fi
    shrenddLog "extractCleanUp:rm ${_DEPLOY_ERROR_DIR}/config_error.log"
    rm -rf "$_actual_template_path_temp"
  fi
  yq -i -P 'sort_keys(..)' "$_actual_template_path"
}

function deleteEmptyKeys {
  while [ "$(cat "$1" | yq 'map(.. | select(tag == "!!map" and length == 0)) | any')" = "true" ]
  do
    yq -i 'del(.. | select(tag == "!!map" and length == 0))' "$1"
  done
}

function spawnTemplate {
  shrenddEchoIfNotSilent "$_TEXT_WARN}}}}spawning{{{{${_CLEAR_TEXT_COLOR}"
  if [ -z "$_SHRENDD_CONFIG" ]; then
    shrenddEchoIfNotSilent "no shrendd_config"
    _config_keys=""
  else
    _config_keys=$(keysFor "$_SHRENDD_CONFIG")
  fi
  _spawn_path=$(echo "$(shrenddOrDefault shrendd.config.path)/${SHRENDD_SPAWN}" | sed -e "s/\/\.\//\//g")
  if [[ "$_spawn_path" == "$_STARTING_DIR"* ]]; then
    :
  else
    _spawn_path=$(echo "$_STARTING_DIR/$(shrenddOrDefault shrendd.config.path)/${SHRENDD_SPAWN}" | sed -e "s/\/\.\//\//g")
  fi
  _spawned_keys=""
  if [ -f "$_spawn_path" ]; then
    shrenddEchoIfNotSilent "${_TEXT_WARN}spawn is present${_CLEAR_TEXT_COLOR}"
  #      cat "${_spawn_path}"
    _spawned_keys=$(keysFor "$(cat "$_spawn_path")")
  fi
  if [ -f "$_spawn_path" ]; then
    shrenddEchoIfNotSilent "spawn does exist: $_spawn_path"
  else
    shrenddEchoIfNotSilent "${_TEXT_INFO}spawn does not exist: $_spawn_path${_CLEAR_TEXT_COLOR}"
    VAR="$_spawn_path"
    DIR="."
    if [[ "$VAR" == *"/"* ]]; then
      DIR=${VAR%/*}
      shrenddLog "config dir: $DIR"
      if [ -d "$DIR" ]; then
        :
      else
        mkdir -p "$DIR"
      fi
    fi
  fi
  for _config_key in $_config_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _yq_name=$(yqName "$_config_key")
    _found="empty"
    export _template_stub=""
    shrenddEchoIfNotSilent "${_TEXT_DEBUG}spawning:${_CLEAR_TEXT_COLOR} \"$_config_key\"->\"$_yq_name\""
    _spawn_default=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" - | yq e ".default" -)
    _spawn_comment=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" - | yq e ".description" -)
    _spawn_neverSpawn=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" - | yq e ".neverSpawn" -)
    if [[ "$_spawn_neverSpawn" == "null" ]] || [[ "$_spawn_neverSpawn" != "true" ]]; then
      _spawn_neverSpawn="false"
    fi
    if [[ "$_spawn_neverSpawn" == "true" ]]; then
      shrenddEchoIfNotSilent "  never stub is true, skipping key"
      continue
    fi
    _has_array="false"
    _drop_key=$(echo "$_config_key" | sed "s/ /$_SPACE_PLACE_HOLDER/g")
    _spawned_keys=$(echo "$_spawned_keys"| sed "s/$_drop_key[^ ]*//g" | sed "s/^ //g" | sed "s/  */ /g")
    if [ "$_spawn_default" == "null" ]; then
      shrenddEchoIfNotSilent "  no default value found."
    else
      shrenddEchoIfNotSilent "  found a default value"
      export _template_stub="$_spawn_default"
      _default_array=$(echo "$_spawn_default" | yq e ".[]" - )
      if [ -z "$_default_array" ]; then
        _has_array="false"
      else
        _has_array="true"
        export _template_stub="$(echo "[${_template_stub/-/{}}]" | sed -e "s/-/},{/g" | sed ':a;N;$!ba;s/\([^{]\)\n\([^}]\)/\1,\2/g'  | sed ':a;N;$!ba;s/\([^}]\)\n\([}]\)/\1,\2/g')"
      fi
      shrenddEchoIfNotSilent "  has array:$_has_array"
    fi
    if [ -f "$_spawn_path" ]; then
      shrenddEchoIfNotSilent "  spawn is present"
    #      cat "${_spawn_path}"
      _found=$(cat "$_spawn_path" | yq e ".$_yq_name" -)
    else
      shrenddEchoIfNotSilent "  no spawn, will try to create it this time."
    fi
    if [ "$_found" ==  "null" ]; then
      shrenddEchoIfNotSilent "  adding to config."
      if [ "$_has_array" == "false" ]; then
        yq -i ".${_yq_name} = strenv(_template_stub)" "$_spawn_path"
        if [ "$_spawn_comment" != "null" ]; then
          shrenddEchoIfNotSilent "  adding comment."
          yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" "$_spawn_path"
        fi
      else
        shrenddEchoIfNotSilent "  trying to add array:\n$_template_stub"
        yq -i ".${_yq_name} = []" "$_spawn_path"
        if [ "$_spawn_comment" != "null" ]; then
          shrenddEchoIfNotSilent "  adding comment."
          yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" "$_spawn_path"
        fi
        yq -i ".${_yq_name} += env(_template_stub)" "$_spawn_path"
      fi
    else
      if [ "$_found" == "empty" ]; then
        shrenddEchoIfNotSilent "  creating new config yaml:$_yq_name"
        if [ "$_has_array" == "false" ]; then
          yq -n ".${_yq_name} = strenv(_template_stub)" > "$_spawn_path"
          if [ "$_spawn_comment" != "null" ]; then
            shrenddEchoIfNotSilent "  adding comment."
            yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" "$_spawn_path"
          fi
        else
          shrenddEchoIfNotSilent "  trying to add array"
          yq -i ".${_yq_name} = []"  > "$_spawn_path"
          if [ "$_spawn_comment" != "null" ]; then
            shrenddEchoIfNotSilent "  adding comment."
            yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" "$_spawn_path"
          fi
          yq -i ".${_yq_name} += env(_template_stub)" "$_spawn_path"
        fi
      else
        shrenddEchoIfNotSilent "  already in spawn."
        if [ "$_spawn_comment" != "null" ]; then
          shrenddEchoIfNotSilent "  adding comment."
          yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" "$_spawn_path"
        fi
      fi
    fi
  done
  if [ -f "$_spawn_path" ]; then
    for _config_key in $_spawned_keys; do
      _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
      _yq_name=$(yqName "$_config_key")
      shrenddEchoIfNotSilent "  checking key: ${_yq_name}"
      if [ "$_yq_name" == "_" ]; then
        shrenddEchoIfNotSilent "  ${_TEXT_WARN}invalid key, if actually present, please manually delete it.${_CLEAR_TEXT_COLOR}"
      else
        shrenddEchoIfNotSilent "${_TEXT_WARN}dropping key:${_yq_name} -> $_config_key${_CLEAR_TEXT_COLOR}"
        shrenddLog "yq to spawn:$_spawn_path"
        yq -i "del(.${_yq_name})" "$_spawn_path"
        shrenddLog "deleted from spawn..."
      fi
    done
    shrenddLog "deleting spawn keys."
    deleteEmptyKeys "$_spawn_path"
#    yq -i 'del(.. | select(tag == "!!map" and length == 0))' "$_spawn_path"
#    yq -i 'del(.. | select(length == 0))' "$_spawn_path"
  fi
  yq -i -P 'sort_keys(..)' "$_spawn_path"
}

function doTemplate {
  if [ "$SHRENDD_EXTRACT" == "true" ]; then
      #write to temp file
      export _IGNORE_REQUIRED="true"
      for _specific_module in $_module; do
        loadConfig $_specific_module
        shrenddEchoIfNotSilent "switching to module: $_the_module"
        cd "$_the_module"
        export _MODULE_DIR=$(pwd)
        initTargets
        export _SHRENDD_DEPLOY_DIRECTORY=$(shrenddOrDefault "shrendd.deploy.dir")
        extractTemplate "$_specific_module"
        unwindConfig
        cd "$_STARTING_DIR"
      done
      #merge and clean up actual config template file
      shrenddEchoIfNotSilent "${_TEXT_INFO}resolving temp template${_CLEAR_TEXT_COLOR}"
      for _specific_module in $_module; do
        loadConfig "$_specific_module"
        shrenddEchoIfNotSilent "switching to module: $_the_module"
        cd "$_the_module"
        export _MODULE_DIR=$(pwd)
        export _SHRENDD_DEPLOY_DIRECTORY=$(shrenddOrDefault "shrendd.deploy.dir")
        initTargets
        extractCleanUp "$_specific_module"
        unwindConfig
        cd "$_STARTING_DIR"
      done
      shrenddEchoIfNotSilent "${_TEXT_INFO}config template updated${_CLEAR_TEXT_COLOR}"
    fi
    export _IGNORE_REQUIRED="false"
    if [ -z "$SHRENDD_SPAWN" ]; then
        :
    else
      export _IGNORE_REQUIRED="true"
      for _specific_module in $_module; do
        loadConfig "$_specific_module"
        shrenddEchoIfNotSilent "switching to module: $_the_module"
        cd "$_the_module"
        export _MODULE_DIR=$(pwd)
        export _SHRENDD_DEPLOY_DIRECTORY=$(shrenddOrDefault "shrendd.deploy.dir")
        shrenddEchoIfNotSilent "trying to load array of targets for: $_MODULE_DIR"
        initTargets
        spawnTemplate "$_specific_module"
        unwindConfig
        cd "$_STARTING_DIR"
      done
    fi
}