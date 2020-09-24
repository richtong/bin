#!/usr/bin/env bash
##
## install Boingo Wi-Finder
## http://www.boingo.com/retail/#s3781
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
Installs Boingo Wi-Finder for auto connecting to Boingo hotspots
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
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh


if in_os mac
then
    log_error 0 "Mac only"
fi

log_verbose looking for app
## https://www.npmjs.com/package/onepass-cli for npm package
if [[ -e "/Applications/Boingo Wi-Finder.app" ]]
then
    log_exit app already installed
fi

log_verbose installing
download_url_open "http://static-assets.boingo.com/apps/macupg003/wifinder-mac10-7.dmg"
