#!/bin/bash
## vim: set noet ts=4 sw=4:
#
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

mkdir -p "$HOME/ws/cache"
ORG_NAME="${ORG_NAME:-tongfamily}"

echo "$SCRIPTNAME does aws cp"

aws s3 cp "s3://$ORG_NAME-build-artifacts/cntk/acml-5-3-1-ifort-64bit.tgz" "$HOME/ws/cache/acml-5-3-1-ifort-64bit.tgz"
