#!/bin/bash

export _test='$(the $(pattern $(of) $(parenthesis)) is $(never ending))$(hello) world!!!'

function untilSed {
  _the='$(the '
  _the_replacement='_the_first_sign '
  _left_parenthesis='$('
  _right_parenthesis=')'
  _left_parenthesis_replacement='_dollar_left_parenthesis_sign '
  _right_parenthesis_replacement=' _right_parenthesis_sign'
  _parsed="${1/$_the/$_the_replacement}"
  _still_parsing="true"
  while [ "${_still_parsing}" = "true" ]
  do
    if [[ "${_parsed}" == *"$_left_parenthesis"* ]]; then
      _parsed="${_parsed//$_left_parenthesis/$_left_parenthesis_replacement}"
    fi
    if [[ "${_parsed}" == *"$_right_parenthesis"* ]]; then
      _parsed="${_parsed//$_right_parenthesis/$_right_parenthesis_replacement}"
    fi
    if [[ "${_parsed}" != *"$_left_parenthesis"* && "${_parsed}" != *"$_right_parenthesis"* ]]; then
      _still_parsing="false"
    fi
  done
}

untilSed "${_test}"