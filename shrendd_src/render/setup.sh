#!/bin/bash
set -euo pipefail

echo "running ansible templating..."
#for more verbose ansible output add: -vvvvv
echo "ansible-playbook $SHRENDD_WORKING_DIR/.shrendd/render/ansible/site.yml -i hosts -e \"template_output_dir=$RENDER_DIR\" -e \"template_input_dir=$TEMPLATE_DIR\" -e @$_config -e \"playbook_operations=render\" -D"
ansible-playbook $SHRENDD_WORKING_DIR/.shrendd/render/ansible/site.yml -i hosts -e "template_output_dir=$RENDER_DIR" -e "template_input_dir=$TEMPLATE_DIR" -e @$_config -e "playbook_operations=render" -D
sleep 1
