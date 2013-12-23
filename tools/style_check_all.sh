#!/bin/sh

# Skip the "Vendor" Directory
find shotvibe -path shotvibe/Vendor -prune -o -name '*.[mh]' -print0 | xargs -0 -n 1 ./tools/style_check_file.sh

true
