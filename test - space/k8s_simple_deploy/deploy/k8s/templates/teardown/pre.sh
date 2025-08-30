#!/usr/bin/env sh

echo "I run before anything of the rest of the teardown scripts, even before the standard teardown"
echo "you can skip the standard teardown by adding 'export SKIP_STANDARD_TEARDOWN=true' somewhere in this file."
#export SKIP_STANDARD_TEARDOWN="true"
#echo "skip set..."