#!/bin/bash

function actualRender {
  _template=$(cat $1)
  _rname=$(echo "$1" | sed -e "s/\.srd//g")
  eval "echo -e \"$_template\"" > $RENDER_DIR/$_rname
}

function doRender {
  _curdir=$(pwd)
  echo "running bash templating..."
  cd $1
  config_files="*.srd"
  echo "files should be in: $config_files"
  for fname in $config_files
  do
    actualRender "$fname"
  done
  cd $_curdir
  pwd
}