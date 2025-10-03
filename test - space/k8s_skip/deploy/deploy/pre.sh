#!/bin/bash

function complexIf {
  shrenddLog "Evaluating complexIf condition..."
  _ralphwiggum="$(getConfig 'ralph.wiggum')"
  _chiefwiggum="$(getConfig 'chief.wiggum')"
  shrenddLog "Checking complexIf condition: \"${_ralphwiggum}\" == \"I'm a brick\" && \"${_chiefwiggum}\" == \"Bake him away, toys.\""
  if [[ "${_ralphwiggum}" == "I'm a brick" ]] && [[ "${_chiefwiggum}" == "Bake him away, toys." ]]; then
    shrenddLog "Condition met."
    echo "true"
  else
    shrenddLog "Condition not met."
    echo "false"
  fi
}