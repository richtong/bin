#!/usr/bin/env bash
##
## install 1Password
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Uninstall and the reInstalls Mac Ports and all its packages
Note this does not work on an OS upgrade.

    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"

EOF
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            # add the -v which works for many commands
            export FLAGS+=" -v "
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

if [[ ! $OSTYPE =~ darwin ]]
then
    log_verbose git install
    ## https://www.npmjs.com/package/onepass-cli for npm package
    git_install_or_update 1pass georgebrock
    exit
fi

temp=$(mktemp)
port -qv installed > "$temp"
log_verbose uninstall all mac ports
sudo port -f uninstall installed
sudo rm -rf /opt/local/var/macports/build/*
log_verbose getting the restore script
download_url "$RESTORE_URL"
log_verbose run restor script
sudo bash "$WS_DIR/cache/$(basename "$RESTORE_URL")" "$temp"
rm "$temp"
