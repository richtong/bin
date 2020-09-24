#!/usr/bin/env bash
##
## The bootstrap for creating secrets for a new hire
##
## It does the following:
##
## 1. Creates a Veracrypt volume on Dropbox
## 2. Moves the current .ssh to the Veracrypt/secrets for stowing
## 3. Generates new keys for the company
## 4. Modifies the .ssh/config to use the keys for our main assets (the company, github and amazon)
##
## After this step which only needs to be done once per hire time (or when you want refreshed keys
##
## Then on a per machine install basis run install.sh to use it
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
$SCRIPTNAME does the following:

1. Creates a Veracrypt volume on Dropbox
2. Moves the current .ssh to the Veracrypt/secrets for stowing
3. Generates new keys for the company
4 Modifies the .ssh/config to use the keys for our main assets (the company, github and amazon)

After this step which only needs to be done once per hire time (or when you want refreshed keys

Then on a per machine install basis run $SCRIPT_DIR/install.sh to use it

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

log_verbose Create a new VeraCrypt volume
"$SCRIPT_DIR/veracrypt-create.sh"

log_verbose Bail existing .ssh into the volume
"$SCRIPT_DIR/secrets-to-veracrypt.sh"

log_verbose create new keys for new hires
"$SCRIPT_DIR/secrets-generate.sh"

log_verbose now stow the new keys
"$SCRIPT_DIR/secrets-stow.sh"

log_verbose per-user initialization complete now run the per-machine install.sh
