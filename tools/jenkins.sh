#!/bin/sh -x

set -e

mkdir -p reports

./tools/style_check_all.sh > reports/style_check.report || true
