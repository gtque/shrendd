#!/bin/bash

function r2 {
  echo "hello, world!"
}

function r1 {
  cat poc_eval_r2.txt
}

function r {
  echo $1
  eval "echo -e \"$1\""
}

r "\$(r1)"