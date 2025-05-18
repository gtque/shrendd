#!/bin/bash

#need to figure out how/what other files beyond the template files need to be scanned
#for the extract
function extractTemplate {
  echo "$_TEXT_WARN{{{{temp extraction started}}}}${_CLEAR_TEXT_COLOR}"
  _template_path="${_SHRENDD_CONFIG_TEMPLATE_PATH}.temp"
  if [ -f $_template_path ]; then
    :
  else
    VAR="$_template_path"
    DIR="."
    if [[ "$VAR" == *"/"* ]]; then
      DIR=${VAR%/*}
      if [ -d $DIR ]; then
        :
      else
        mkdir -p $DIR
      fi
    fi
    echo "" > $_template_path
  fi
  _actual_template_path=$(pwd)
  _actual_template_path=$(echo "$_actual_template_path/$_template_path")
  export _template_stub=$(cat $_STARTING_DIR/.shrendd/render/config/template.yml)
  _current_template=""
  _checker=""
  _curdir=$(pwd)
  _files_extracted=""
  if [ -d $_SHRENDD_DEPLOY_DIRECTORY ]; then
    echo "${_TEXT_INFO}found deploy directory, extracting from: $_SHRENDD_DEPLOY_DIRECTORY${_CLEAR_TEXT_COLOR}"
    cd "$_SHRENDD_DEPLOY_DIRECTORY"
    _deploy_files=$(find . -type f -print)
#    find . -type f -print0 | while IFS= read -r -d $'\0' fname; do
  #        rm -rf $_DEPLOY_ERROR_DIR/config_error.log
    while IFS= read -r fname; do
      _files_extracted="$(echo "$_files_extracted $(pwd)$fname" | sed "s/\.\//\//g")"
      echo -e "extracting $fname>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      _template=$(cat $fname | sed -e "s/\\\${\([^}]*\)}/\\\$(getConfig \"\1\")/g")
      echo "getConfig"
      _scanner="$(echo "$_template" | grep -o "\$(getConfig [^)]*)" || echo "not found")"
      while IFS= read -r match; do
        # Your action here, using the $match variable
        if [ "$match" != "not found" ]; then
          count=$(echo "$match" | grep -o "getConfig" | wc -l)
          match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty//g" | sed -e "s/\\\$(getConfig//g" | sed -e "s/)//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
          echo "  Found: $match"
          if [ "$count" -gt 1 ]; then
            echo "    nested reference found";
            echo "nested reference found: $match ($fname)-> cannot full extract, please add any indirectly referenced configs to the template." >> $_DEPLOY_ERROR_DIR/render_warning.log
          fi
          _already_found=$(echo "$_checker" | grep "$match" || echo "not found")
          if [ "$_already_found" != "not found" ]; then
            echo "   already found.."
          else
            _checker="$(echo "$_checker\n$match")"
            echo "   not found, adding to list"
          fi
        fi
      done <<< "$_scanner"
      echo "getConfigOrEmpty:"
      _scanner="$(echo "$_template" | grep -o "\$(getConfigOrEmpty [^)]*)" || echo "not found")"
  #         echo "$_scanner" | while read match; do
      while IFS= read -r match; do
        # Your action here, using the $match variable
        if [ "$match" != "not found" ]; then
          count=$(echo "$match" | grep -o "getConfig" | wc -l)
          match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty//g" | sed -e "s/\\\$(getConfig//g" | sed -e "s/)//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
          echo "  Found: $match"
          if [ "$count" -gt 1 ]; then
            echo "    nested reference found";
            echo "nested reference found: $match ($fname)-> cannot full extract, please add any indirectly referenced configs to the template." >> $_DEPLOY_ERROR_DIR/render_warning.log
          fi
          _already_found=$(echo "$_checker" | grep "$match" || echo "not found")
          if [ "$_already_found" != "not found" ]; then
            echo "   already found.."
          else
            _checker="$(echo "$_checker\n$match")"
            echo "   not found, adding to list"
          fi
        fi
      done <<< "$_scanner"
      echo -e "end $fname<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    done <<< "$_deploy_files"
    cd $_curdir
  fi
  for _target in $targets; do
    export target="$_target"
    echo "extracting: $target"
    echo "initializing target template directory"
    targetDirs "$target"
    if [ -d "$TEMPLATE_DIR" ]; then
      _curdir=$(pwd)
      echo "running bash templating..."
      cd $TEMPLATE_DIR
      config_files="*.srd"
      echo "files should be in: $config_files"
      for fname in $config_files; do
        rm -rf $_DEPLOY_ERROR_DIR/config_error.log
        fname_q="$(echo "$(pwd)$fname" | sed "s/\.\//\//g")"
        if [ "$_files_extracted" != *"$fname_q "* ]; then
          _files_extracted="$(echo "$_files_extracted $fname_q")"
          echo -e "extracting $fname>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
          _template=$(cat $fname | sed -e "s/\\\${\([^}]*\)}/\\\$(getConfig \"\1\")/g")
          echo "getConfig"
          _scanner="$(echo "$_template" | grep -o "\$(getConfig [^)]*)" || echo "not found")"
          while IFS= read -r match; do
            # Your action here, using the $match variable
            if [ "$match" != "not found" ]; then
              count=$(echo "$match" | grep -o "getConfig" | wc -l)
              match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty//g" | sed -e "s/\\\$(getConfig//g" | sed -e "s/)//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
              echo "  Found: $match"
              if [ "$count" -gt 1 ]; then
                echo "    nested reference found";
                echo "nested reference found: $match ($fname)-> cannot full extract, please add any indirectly referenced configs to the template." >> $_DEPLOY_ERROR_DIR/render_warning.log
              fi
              _already_found=$(echo "$_checker" | grep "$match" || echo "not found")
              if [ "$_already_found" != "not found" ]; then
                echo "   already found.."
              else
                _checker="$(echo "$_checker\n$match")"
                echo "   not found, adding to list"
              fi
            fi
          done <<< "$_scanner"
          echo "getConfigOrEmpty:"
          _scanner="$(echo "$_template" | grep -o "\$(getConfigOrEmpty [^)]*)" || echo "not found")"
  #         echo "$_scanner" | while read match; do
          while IFS= read -r match; do
            # Your action here, using the $match variable
            if [ "$match" != "not found" ]; then
              count=$(echo "$match" | grep -o "getConfig" | wc -l)
              match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty//g" | sed -e "s/\\\$(getConfig//g" | sed -e "s/)//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
              echo "  Found: $match"
              if [ "$count" -gt 1 ]; then
                echo "    nested reference found";
                echo "nested reference found: $match ($fname)-> cannot full extract, please add any indirectly referenced configs to the template." >> $_DEPLOY_ERROR_DIR/render_warning.log
              fi
              _already_found=$(echo "$_checker" | grep "$match" || echo "not found")
              if [ "$_already_found" != "not found" ]; then
                echo "   already found.."
              else
                _checker="$(echo "$_checker\n$match")"
                echo "   not found, adding to list"
              fi
            fi
          done <<< "$_scanner"
          echo -e "end $fname<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        else
          echo "already extracted: $fname_q"
        fi
      done
      cd $_curdir
    fi
  done
  echo "${_TEXT_INFO}templating the template${_CLEAR_TEXT_COLOR}"
  echo -e "$_checker" | while read match; do
    _o_match="$match"
    match=$(echo "$match" | sed -e "s/\\\$(getConfigOrEmpty//g" | sed -e "s/\\\$(getConfig//g" | sed -e "s/)//g" | sed -e "s/\"//g" | tr "[:upper:]" "[:lower:]" | sed -e 's/^[[:space:]]*//' | cut -d'[' -f1)
    match=$(echo "$match" | sed -e 's/\([a-zA-Z0-9 _-]\+ \+[a-zA-Z0-9 _-]\+\)/[\"\1\"]/g')
    if [[ "$match" == *"-"* ]]; then
      :
    else
      match=$(echo "$match" | sed -e "s/_/\./g")
    fi
    if [ -n "$match" ]; then
      echo "  extracted: $_o_match => $match"  # Example: Print the match
      _found="empty"
      _current_template_yaml=$(cat $_actual_template_path)
      if [ -z "$_current_template_yaml" ]; then
        echo "    template is empty"
      else
        echo "    template is not empty"
        _found=$(cat "$_actual_template_path" | yq e ".$match" -)
      fi
      if [ "$_found" ==  "null" ]; then
        echo "    adding to template."
        yq -i ".$match = strenv(_template_stub)" $_actual_template_path
      else
        if [ "$_found" == "empty" ]; then
          echo "    creating new template yaml:$match"
          yq -n ".$match = strenv(_template_stub)" > $_actual_template_path
        else
          echo "    already in template."
        fi
      fi
    fi
  done
  echo "${_TEXT_INFO}temp template complete${_CLEAR_TEXT_COLOR}"
}

function extractCleanUp {
  echo "$_TEXT_WARN{{{{extraction started}}}}${_CLEAR_TEXT_COLOR}"
  _template_path="${_SHRENDD_CONFIG_TEMPLATE_PATH}"
  _template_path_temp="${_SHRENDD_CONFIG_TEMPLATE_PATH}.temp"
  if [ -f $_template_path_temp ]; then
    if [ -f $_template_path ]; then
      :
    else
      VAR="$_template_path"
      DIR="."
      if [[ "$VAR" == *"/"* ]]; then
        DIR=${VAR%/*}
        if [ -d $DIR ]; then
          :
        else
          mkdir -p $DIR
        fi
      fi
      echo "" > $_template_path
    fi
    _actual_template_path=$(pwd)
    _actual_template_path=$(echo "$_actual_template_path/$_template_path")
    _actual_template_path_temp=$(echo "$(pwd)/$_template_path_temp")
    echo "temp path: $_actual_template_path_temp"
    export _template_stub=$(cat $_STARTING_DIR/.shrendd/render/config/template.yml)
    _template_keys=""
    if [ -f $_actual_template_path ]; then
      echo "${_TEXT_WARN}template is present${_CLEAR_TEXT_COLOR}"
      _template_keys=$(keysFor "$(cat $_actual_template_path)")
#      echo "current keys: \"$_template_keys\""
    fi
    _template_keys_temp=""
    if [ -f $_actual_template_path_temp ]; then
      echo "${_TEXT_WARN}temp template is present${_CLEAR_TEXT_COLOR}"
      _template_keys_temp=$(keysFor "$(cat $_actual_template_path_temp)")
#      echo "current temp keys: \"$_template_keys_temp\""
    fi
    for _config_key in $_template_keys_temp; do
      _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
      _yq_name=$(yqName "$_config_key")
      _found="empty"
      echo -e "${_TEXT_DEBUG}templating:${_CLEAR_TEXT_COLOR} \"$_config_key\"->\"$_yq_name\""
      _has_array="false"
      _drop_key=$(echo "$_config_key" | sed "s/ /$_SPACE_PLACE_HOLDER/g")
      _template_keys=$(echo "$_template_keys"| sed "s/$_drop_key[^ ]*//g" | sed "s/^ //g" | sed "s/  */ /g")
      if [ -f $_actual_template_path ]; then
        _found=$(cat $_actual_template_path | yq e ".$_yq_name" -)
      else
        echo "  no template, will try to create it this time."
      fi
      if [ "$_found" ==  "null" ]; then
        echo "  adding to config."
        if [ "$_has_array" == "false" ]; then
          yq -i ".${_yq_name} = strenv(_template_stub)" $_actual_template_path
        else
          echo -e "  trying to add array:\n$_template_stub"
          yq -i ".${_yq_name} = []" $_actual_template_path
          yq -i ".${_yq_name} += env(_template_stub)" $_actual_template_path
        fi
      else
        if [ "$_found" == "empty" ]; then
          echo "  creating new config yaml:$_yq_name"
          if [ "$_has_array" == "false" ]; then
            yq -n ".${_yq_name} = strenv(_template_stub)" > $_actual_template_path
          else
            echo "  trying to add array"
            yq -i ".${_yq_name} = []"  > $_actual_template_path
            yq -i ".${_yq_name} += env(_template_stub)" $_actual_template_path
          fi
        else
          echo "  already in template."
        fi
      fi
    done
    if [ -f $_template_path ]; then
      _template_yaml=$(cat $_template_path)
      echo "${_TEXT_INFO}reducing keys${_CLEAR_TEXT_COLOR}"
      for _config_key in $_template_keys; do
        _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
        _yq_name=$(yqName "$_config_key")
#        echo "$_template_yaml" | yq e ".$_yq_name" -
        _indirect=$(echo "$_template_yaml" | yq e ".$_yq_name" - | yq e ".indirect" -)
        if [ "$_indirect" != "null" ] && [ "$_indirect" == "true" ]; then
          echo "  indirectly referenced, not dropping: $_yq_name"
        else
          echo "  ${_TEXT_WARN}dropping key:$_config_key${_CLEAR_TEXT_COLOR}"
          yq -i "del(.${_yq_name})" $_actual_template_path
        fi
      done
      yq -i 'del(.. | select(tag == "!!map" and length == 0))' $_actual_template_path
      yq -i 'del(.. | select(tag == "!!map" and length == 0))' $_actual_template_path
    fi
    rm -rf $_actual_template_path_temp
  fi
}

function spawnTemplate {
  echo -e "$_TEXT_WARN}}}}spawning{{{{${_CLEAR_TEXT_COLOR}"
  if [ -z "$_SHRENDD_CONFIG" ]; then
    echo "no shrendd_config"
    _config_keys=""
  else
    _config_keys=$(keysFor "$_SHRENDD_CONFIG")
  fi
  _spawn_path=$(echo "$_STARTING_DIR/$(shrenddOrDefault shrendd.config.path)/${SHRENDD_SPAWN}" | sed -e "s/\/\.\//\//g")
  _spawned_keys=""
  if [ -f $_spawn_path ]; then
    echo "${_TEXT_WARN}spawn is present${_CLEAR_TEXT_COLOR}"
  #      cat "${_spawn_path}"
    _spawned_keys=$(keysFor "$(cat $_spawn_path)")
  fi
  if [ -f $_spawn_path ]; then
    echo "spawn does exist: $_spawn_path"
  else
    echo "${_TEXT_INFO}spawn does not exist: $_spawn_path${_CLEAR_TEXT_COLOR}"
    VAR="$_spawn_path"
    DIR="."
    if [[ "$VAR" == *"/"* ]]; then
      DIR=${VAR%/*}
      echo "config dir: $DIR"
      if [ -d $DIR ]; then
        :
      else
        mkdir -p $DIR
      fi
    fi
  fi
  for _config_key in $_config_keys; do
    _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
    _yq_name=$(yqName "$_config_key")
    _found="empty"
    export _template_stub=""
    echo -e "${_TEXT_DEBUG}spawning:${_CLEAR_TEXT_COLOR} \"$_config_key\"->\"$_yq_name\""
    _spawn_default=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" - | yq e ".default" -)
    _spawn_comment=$(echo "$_SHRENDD_CONFIG" | yq e ".$_yq_name" - | yq e ".description" -)
    _has_array="false"
    _drop_key=$(echo "$_config_key" | sed "s/ /$_SPACE_PLACE_HOLDER/g")
    _spawned_keys=$(echo "$_spawned_keys"| sed "s/$_drop_key[^ ]*//g" | sed "s/^ //g" | sed "s/  */ /g")
    if [ "$_spawn_default" == "null" ]; then
      echo "  no default value found."
    else
      echo "  found a default value"
      export _template_stub="$_spawn_default"
      _default_array=$(echo "$_spawn_default" | yq e ".[]" - )
      if [ -z "$_default_array" ]; then
        _has_array="false"
      else
        _has_array="true"
        export _template_stub="$(echo "[${_template_stub/-/{}}]" | sed -e "s/-/},{/g" | sed ':a;N;$!ba;s/\([^{]\)\n\([^}]\)/\1,\2/g'  | sed ':a;N;$!ba;s/\([^}]\)\n\([}]\)/\1,\2/g')"
      fi
      echo "  has array:$_has_array"
    fi
    if [ -f $_spawn_path ]; then
      echo "  spawn is present"
    #      cat "${_spawn_path}"
      _found=$(cat $_spawn_path | yq e ".$_yq_name" -)
    else
      echo "  no spawn, will try to create it this time."
    fi
    if [ "$_found" ==  "null" ]; then
      echo "  adding to config."
      if [ "$_has_array" == "false" ]; then
        yq -i ".${_yq_name} = strenv(_template_stub)" $_spawn_path
        if [ "$_spawn_comment" != "null" ]; then
          echo "  adding comment."
          yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" $_spawn_path
        fi
      else
        echo -e "  trying to add array:\n$_template_stub"
        yq -i ".${_yq_name} = []" $_spawn_path
        if [ "$_spawn_comment" != "null" ]; then
          echo "  adding comment."
          yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" $_spawn_path
        fi
        yq -i ".${_yq_name} += env(_template_stub)" $_spawn_path
      fi
    else
      if [ "$_found" == "empty" ]; then
        echo "  creating new config yaml:$_yq_name"
        if [ "$_has_array" == "false" ]; then
          yq -n ".${_yq_name} = strenv(_template_stub)" > $_spawn_path
          if [ "$_spawn_comment" != "null" ]; then
            echo "  adding comment."
            yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" $_spawn_path
          fi
        else
          echo "  trying to add array"
          yq -i ".${_yq_name} = []"  > $_spawn_path
          if [ "$_spawn_comment" != "null" ]; then
            echo "  adding comment."
            yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" $_spawn_path
          fi
          yq -i ".${_yq_name} += env(_template_stub)" $_spawn_path
        fi
      else
        echo "  already in spawn."
        if [ "$_spawn_comment" != "null" ]; then
          echo "  adding comment."
          yq -i "(.${_yq_name} | key) head_comment=\"$_spawn_comment\"" $_spawn_path
        fi
      fi
    fi
  done
  if [ -f $_spawn_path ]; then
    for _config_key in $_spawned_keys; do
      _config_key=$(echo "$_config_key" | sed -e "s/$_SPACE_PLACE_HOLDER/ /g")
      _yq_name=$(yqName "$_config_key")
      echo "${_TEXT_WARN}dropping key:$_config_key${_CLEAR_TEXT_COLOR}"
      yq -i "del(.${_yq_name})" $_spawn_path
    done
    yq -i 'del(.. | select(tag == "!!map" and length == 0))' $_spawn_path
  fi
}

function doTemplate {
  if [ "$SHRENDD_EXTRACT" == "true" ]; then
      #write to temp file
      export _IGNORE_REQUIRED="true"
      for _specific_module in $_module; do
        loadConfig $_specific_module
        echo "switching to module: $_the_module"
        cd $_the_module
        export _MODULE_DIR=$(pwd)
        initTargets
        export _SHRENDD_DEPLOY_DIRECTORY=$(shrenddOrDefault "shrendd.deploy.dir")
        extractTemplate $_specific_module
        unwindConfig
        cd $_STARTING_DIR
      done
      #merge and clean up actual config template file
      echo "${_TEXT_INFO}resolving temp template${_CLEAR_TEXT_COLOR}"
      for _specific_module in $_module; do
        loadConfig $_specific_module
        echo "switching to module: $_the_module"
        cd $_the_module
        export _MODULE_DIR=$(pwd)
        export _SHRENDD_DEPLOY_DIRECTORY=$(shrenddOrDefault "shrendd.deploy.dir")
        initTargets
        extractCleanUp $_specific_module
        unwindConfig
        cd $_STARTING_DIR
      done
      echo "${_TEXT_INFO}config template updated${_CLEAR_TEXT_COLOR}"
    fi
    export _IGNORE_REQUIRED="false"
    if [ -z "$SHRENDD_SPAWN" ]; then
        :
    else
      export _IGNORE_REQUIRED="true"
      for _specific_module in $_module; do
        loadConfig $_specific_module
        echo "switching to module: $_the_module"
        cd $_the_module
        export _MODULE_DIR=$(pwd)
        export _SHRENDD_DEPLOY_DIRECTORY=$(shrenddOrDefault "shrendd.deploy.dir")
        echo "trying to load array of targets for: $_MODULE_DIR"
        initTargets
        spawnTemplate $_specific_module
        unwindConfig
        cd $_STARTING_DIR
      done
    fi
}