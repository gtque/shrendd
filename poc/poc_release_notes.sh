#!/bin/bash

_release_notes="$(cat "./build/release_notes/${1}.txt")"
#_release_notes="${_release_notes//$'\\r'/}"
#_release_notes="${_release_notes//$'\\n'/\\\\n}"
_release_notes=$(echo "$_release_notes" | sed 's/\r//g' | sed ':a;N;$!ba;s/\n/\\n/g' )
echo "$_release_notes"
echo "$_release_notes" > poc/r_notes.poc