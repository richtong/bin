#!/usr/bin/env bash
##
## test lib-config.sh
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
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo Install 1Password
            echo usage: $SCRIPTNAME [ flags ]
            echo
            echo "flags: -d debug, -v verbose, -h help"
            echo
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-config.sh

BREW_GNU="${BREW_GNU:-"/usr/local/opt/coreutils/libexec/gnubin"}"
NEW_PATH="${NEW_PATH:-"$BREW_GNU:\$PATH"}"
EXPORT="export PATH=$NEW_PATH"
echo export command is $NEW_PATH
eval export PATH=$NEW_PATH
echo PATH after export $PATH
eval $EXPORT
echo PATH after eval $PATH
hash -r

if ! config_mark foo
then
    log_verbose creating mark for foo
fi

log_verbose config_add_once
config_add_once foo "export PATH=$NEW_PATH"
exit

log_verbose here document now
config_add foo <<<"now"

config_add foo <<-EOF
multiline
multiline
EOF

log_verbose use trying to get echo there
echo trying to get an echo there | config_add foo

log_verbose adding a sequence
seq 1 14 | config_add foo

echo car{0..3}{front,back,driver,outside{1..5}} | config_add foo
