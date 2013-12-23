#!/bin/bash

# This is a good explanation of the mechanism that is being used in this
# script:
#
# http://briancoyner.github.io/blog/2013/06/20/generating-xcode-errors/


# The following is a hack to only check the currently open file in Xcode. This
# is done since Xcode only shows up to 200 warnings, and we currently have much
# more than this in the project. By only checking the current file, we make
# sure that all warnings in the file are shown

path=$(osascript <<APPLESCRIPT

tell application "Xcode"
    set current_document to last source document
    set current_document_path to path of current_document
end tell

APPLESCRIPT
)


# Only check if the file is an Objective-C source code file
if [[ $path =~ (.m|.h)$ ]]
then
  ./tools/uncrustify -c uncrustify.cfg -l OC -f "$path" | ./tools/diffstyle.py --msg-template="{path}:{line}:{col}: warning: {msg}" "$path"
fi

# Always return success in order to not cause the build to fail
true
