#!/bin/bash
#
#
set -e && SCRIPTNAME=$(basename $0)

mkdir -p "$HOME/ws/cache"
ORG_NAME="${ORG_NAME:-tongfamily}"

aws s3 cp "s3://$ORG_NAME-build-artifacts/cntk/acml-5-3-1-ifort-64bit.tgz" "$HOME/ws/cache/acml-5-3-1-ifort-64bit.tgz"
