#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
#
## Change the password of a secrets
## This wraps the keys in the new bcrypt format using openssh version 6.5
## There is an option to rewrap keys as well
##
set -u && SCRIPTNAME=$(basename $0)
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
FORCE="${FORCE:-false}"
FLAGS="${FLAGS:-""}"
ROUNDS="${ROUNDS:-256}"
while getopts "hdvfa:" opt
do
    case "$opt" in
        h)
            cat <<-EOF

Manages the password on a secrets file

usage: $SCRIPTNAME [flags...] [secrets...]

flags: -d debug, -v verbose, -h help
       -a rounds for the extneral format (default: $ROUNDS)
       -f if a key exists already overwrite it (default: $FORCE)
EOF

            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            FLAGS+=" -v "
            ;;
        f)
            FORCE=true
            ;;
    esac
done
# Need to reset key file fir there is a change
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND-1))
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for key in "$@"
do

    # http://security.stackexchange.com/questions/39279/stronger-encryption-for-ssh-keys
    # -o to use the new bcrypt format with -a 256 rounds
    log_verbose enter a secure passphrase, the key is unrecoverable if you lose the phrase
    # https://www.tedunangst.com/flak/post/new-openssh-key-format-and-bcrypt-pbkdf
    log_verbose rewrap the key in bcrypt with $ROUNDS and change the passphrase
    chmod u+w "$key"
    log_verbose note that adding bcrypt to existing key is not enough to change comments
    log_verbose seems to be a bug the bcrypt format seems to work but not comment change
    ssh-keygen -o -a "$ROUNDS" -f "$key" -C "$key" -p

    log_verbose make $key read only
    chmod 400 "$key"

    log_warning $key new passphrase set make sure to save somewhere like 1Password or Enpass

done
