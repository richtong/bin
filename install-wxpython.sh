#!/usr/bin/env bash
## The above gets the wxpython widgets framework on Ubuntu
##
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

sudo apt-get update

sudo apt -y install python-wxgtk3.0 python-wxgtk-media3.0
sudo apt -y install wxglade

exit
