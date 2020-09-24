#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Use make a strong encrypted password from clear text
##
## uses by install-suers.sh when creating passowrds for people
##
## @author Rich Tong
## @returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME create an encrypted password ready for chpasswd
            echo flags: -d debug, -h help, -v verbose
            echo parameter: the clear text password
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

set -u

# http://unix.stackexchange.com/questions/81240/manually-generate-password-for-etc-shadow/81248#81248
if ! command -v makepasswd
sudo apt-get install -y makepasswd
fi
SALT=$(makepasswd --chars 16)
# Using SHA 512 with lots of rounds
# Default rounds is 5000, so with faster computers
# http://security.stackexchange.com/questions/39450/sha-512-unix-passwords-how-secure-are-those-hashes-really
# But the --rounds=10000 does not seem to work
#

if ! command -v mkpasswd
then
sudo apt-get whois
if
mkpasswd --method=sha-512 --salt="$SALT" --stdin <<< "$1"
