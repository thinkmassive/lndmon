#!/bin/bash

SCRIPT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../provisioning/dashboards"

# All commands expect to run from the directory containing this script
cd "$SCRIPT_DIR"

echo "Checking for prerequisites..."
MISSING_PREREQ=0
#if ! type jsonnet 2> /dev/null; then
#  echo 'jsonnet not found, you may install it with:'
#  echo '  go install github.com/google/go-jsonnet/cmd/jsonnet@latest'
#  MISSING_PREREQ=1
#fi
#if ! type jb 2> /dev/null; then
#  echo 'jsonnet-bundler (jb) not found, you may install it with:'
#  echo '  go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest'
#  MISSING_PREREQ=1
#fi
if ! type mixtool 2> /dev/null; then
  echo 'mixtool not found, you may install it with:'
  echo '  go install github.com/monitoring-mixins/mixtool/cmd/mixtool@main'
  MISSING_PREREQ=1
fi
[ $MISSING_PREREQ -ne 0 ] && exit 1 || echo

# Install grafonnet-lib if it doesn't already exist
if [ ! -e vendor/grafonnet ]; then
  echo "graffonnet-lib not found, installing it now..."
  jb init
  jb install https://github.com/grafana/grafonnet-lib/grafonnet
  echo
fi

echo -e "Generating dashboards in output dir:\n  $OUTPUT_DIR"
mixtool generate dashboards mixin.libsonnet --directory $OUTPUT_DIR
