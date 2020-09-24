#!/usr/bin/env bash
##
##  install mysql client
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# for bashdb
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install Mysql client
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -r release of node [default: $VERSION]"
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

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh
shift $((OPTIND-1))

if ! in_os mac
then
    log_exit "Mac only"
fi

log_verbose install mysql
package_install mysql-client

log_verbose installing into $(config_profile)
if ! config_mark
then
    config_add $<<-'EOF'
PATH="/usr/local/opt/mysql-client/bin:$PATH"
EOF
fi

log_verbose source $profile to use or reboot
