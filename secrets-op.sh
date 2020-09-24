#!/usr/bin/env bash
##
## Moves ssh keys to a new location
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
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS=${FLAGS:-" -v "}
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Move and manage the private, public and fingerprint together

usage: $SCRIPTNAME [ flags ] [operation] source_key destination_key
flags: -d debug, -v verbose, -h help"

operations runs any command and script so some valid operation:
        rm     remove the secrets
        cp     copy to a new place
        mv     move the secrets to a new name

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
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

shift $((OPTIND-1))

if (( $# < 3 ))
then
    log_warning "Need three arguments"
    exec "$SCRIPTNAME" -h
fi

cmd="$1"
src="$2"
dest="$3"

for ext in "" .pub .fingerprint
do
    $cmd "$src$ext" "$dest$ext"
done

# https://serverfault.com/questions/309171/possible-to-change-email-address-in-keypair
# This works for anything in bcrypt format
log_verbose change the comment to match $dest for private key
ssh-keygen -c -C "$dest" -f "$dest"


# https://unix.stackexchange.com/questions/23590/ssh-public-key-comment-separator
log_verbose change the comment for $dest.pub by changing any text after the double equals
sed -i "$dest.pub" "s/== .*/== $dest/"
