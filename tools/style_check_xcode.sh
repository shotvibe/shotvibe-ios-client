#!/bin/bash

# This is a good explanation of the mechanism that is being used in this
# script:
#
# http://briancoyner.github.io/blog/2013/06/20/generating-xcode-errors/

UNCRUSTIFY=./tools/uncrustify

export UNCRUSTIFY

run_uncrustify() {
  $UNCRUSTIFY -c uncrustify.cfg -l OC -f "$1" | ./tools/diffstyle.py --msg-template="{path}:{line}:{col}: warning: {msg}" "$1"
  return 0
}

export -f run_uncrustify

# Skip the "Vendor" Directory
find shotvibe -path shotvibe/Vendor -prune -o -name '*.[mh]' -print0 | xargs -0 -P 4 -n 1 -I {} $BASH -c 'run_uncrustify {}'

# Always return success in order to not cause the build to fail
true
