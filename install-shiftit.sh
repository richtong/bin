#!/usr/bin/env bash
## shiftit does mac windows management
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename $0)
trap 'exit $?' ERR
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
APP="${APP:-"ShiftIt"}"
URL="${URL:-"https://github.com/fikovnik/ShiftIt/releases/download/version-1.6.3/ShiftIt-1.6.3.zip"}"
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo install $APP
            echo usage: $SCRIPTNAME [flags] [app [url]]
            echo flags: -d debug, -h help
            echo positionals:
            echo "   app (default: $APP)"
            echo "   url (default: $URL)"
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
shift $((OPTIND-1))
APP="${1:-"$APP"}"
URL="${2:-"$URL"}"
"$SCRIPT_DIR/install-macapp.sh" "$APP" "$URL"

log_verbose Shiftit installed now configure it
open "/Applications/$APP.app"
