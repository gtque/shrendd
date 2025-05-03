#!/bin/bash

_file1=$(cat ./poc/yq/file1.yml)
_file2="./poc/yq/file2.yml"
echo "file 1:"
echo "$_file1"
echo "-----------------------------------"
echo "file 2:"
cat $_file2
echo ""
echo "-----------------------------------"
#echo "$_file1" | yq e ". as \$d1 | load(\"$_file2\") as \$d2 | (\$d1 | .paths | keys | .[]) as \$i ireduce(\$d2; .paths[\$i] = .paths[\$i] // \$d1.paths[\$i])" -
echo "$_file1" | yq eval-all '. as $item ireduce ({}; . * $item )' - $_file2