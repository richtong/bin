#!/usr/bin/env bash
##
## List large files in git
## https://stackoverflow.com/questions/10622179/how-to-find-identify-large-commits-in-git-history
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
VERSION="${VERSION:-7}"
DIRS="${DIRS:-""}"
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs 1Password
    usage: $SCRIPTNAME [ flags ] [repos...] (default is $PWD)
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
source_lib lib-util.sh

DIRS+="$@"
if [[ -z $DIRS ]]
then
    log_verbose no directorys found use $PWD
    DIRS="$PWD"
fi
for dir in "$DIRS"
do
    log_verbose checking "$dir"
    if ! git rev-list --objects --all \
        | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
        | sed -n 's/^blob //p' \
        | sort --numeric-sort --key=2 \
        | cut -c 1-12,41- \
        | $(command -v gnumfmt || echo numfmt) --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest
    then
        log_warning error with $dir continuing
        continue
    fi
done
