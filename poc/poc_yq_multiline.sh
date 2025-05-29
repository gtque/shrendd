#!/bin/bash

export _file=$(cat ./yq/file3.sh)
_yq=$(yq --null-input ".data.[\"file2.sh\"] += strenv(_file)")
echo -e "$_yq"