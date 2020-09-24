#!/usr/bin/env bash
##
## Add a new user to the machine
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
SET_PASSWORD=${SET_PASSWORD:-false}
# Hint The default is an encrypted version of the usual password
# shellcheck disable=SC2016
PASSWORD=${PASSWORD:-'$6$8LMtrP9m5nsLVzxi$sVod2Xc3kdFU9BA0wkntnlsBbz8bGwS32YIrTrLC1huzcKXBBQXbBiUekKLGMYDlwEU0xmty2QiHYdz4MnO0a/'}
HOME_ROOT=${HOME_ROOT:-$(readlink -f "$HOME/..")}
KEY_DIR=${KEY_DIR:-"public-keys"}
NEW_UID=${NEW_UID:-$(id -u)}
# Ubuntu does not have names for default groups, so just use the gid and ignore the error
NEW_GROUP=${NEW_GROUP:-$(id -g -n 2>/dev/null || true )}
USER_TYPE=${USER_TYPE:-user}
NEW_USER=${NEW_USER:-$USER}
EXTRA_GROUPS=${EXTRA_GROUPS:-"dev,sudo,docker"}
ORG_NAME="${ORG_NAME:-"tongfamily"}"
GITHUB_NAME=${GITHUB_NAME:-"$ORG_NAME-$NEW_USER"}
EMAIL=${EMAIL:-"$NEW_USER@$ORG_NAME"}
while getopts "hdvk:fx:i:g:s:e:n:m:t:" opt
do
    case "$opt" in
        h)
            echo "$SCRIPTNAME: reads user and uid from standard input"
            echo flags: -d debug, -h help -v verbose
            echo "      -k key repo (default: $GIT_REPOS/$KEY_DIR)"
            echo "      -f force the password reset (default: $SET_PASSWORD)"
            echo "      -x default password (the default is the normal one"
            echo "         to create a new default use make-password.sh"
            echo "      -i new uid (default: $NEW_UID)"
            echo "      -g new primary group name (default: $NEW_GROUP)"
            echo "      -t user type (default: $USER_TYPE)"
            echo "      -s new user name (default: $NEW_USER)"
            echo "      -e extra groups (default: $EXTRA_GROUPS)"
            echo "      -n github login name (default: $GITHUB_NAME)"
            echo "      -m email name of new user (default: $EMAIL)"
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            ;;
        k)
            KEY_DIR="$OPTARG"
            ;;
        f)
            SET_PASSWORD=true
            ;;
        x)
            PASSWORD="$OPTARG"
            ;;
        i)
            NEW_UID="$OPTARG"
            ;;
        g)
            NEW_GROUP="$OPTARG"
            ;;
        t)
            USER_TYPE="$OPTARG"
            ;;
        s)
            NEW_USER="$OPTARG"
            ;;
        e)
            EXTRA_GROUPS="$OPTARG"
            ;;
        n)
            GITHUB_NAME="$OPTARG"
            ;;
        m)
            EMAIL="$OPTARG"
            ;;
        *)
            echo "no flag -opt" >&2
    esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

# note the git repo location only after WS_DIR found by include.sh
GIT_REPOS=${GIT_REPOS:-"$WS_DIR/git"}

if [[ -z "$NEW_UID" || "$NEW_UID" =~ ^# ]]
then
    log_verbose ignore absent uid or if it starts with a # sign
    exit 0
fi

log_verbose "adding: $NEW_UID $NEW_USER $NEW_GROUP $USER_TYPE $EXTRA_GROUPS $GITHUB_NAME $EMAIL"

if ! getent passwd "$NEW_USER" > /dev/null
then
    log_verbose "Adding a new $NEW_USER"
    sudo adduser \
        --uid "$NEW_UID" \
        --ingroup "$NEW_GROUP" \
        --gecos "${NEW_USER^}" \
        --disabled-password \
        "$NEW_USER"

    sudo usermod -a -G "$EXTRA_GROUPS" "$NEW_USER"

    # set a password only if asked and one is not already there
    if $SET_PASSWORD && ! sudo grep "^$NEW_USER" /etc/shadow | cut -d':' -f2 | grep -v "\$"
    then
        log_verbose "Changing $NEW_USER password"
        # Make sure to use sha512 as the strongest password
        echo "$NEW_USER:$PASSWORD" | sudo chpasswd -e
    fi

elif (( $(id -u "$NEW_USER") != "$NEW_UID" ))
then
    log_verbose "changing $NEW_USER to use $NEW_UID"
    if (( $(id -u) == $(id -u "$NEW_USER") ))
    then
        >&2 echo "$SCRIPTNAME: cannot change the current user $USER"

    else
        OLD_UID=$(id -u "$NEW_USER")
        if ! sudo usermod -u "$NEW_UID" "$NEW_USER"
        then
            >&2 echo "$SCRIPTNAME: could not change $NEW_USER"
            return
        fi
        # get the GID for the NEW_GROUP
        NEW_GID=$(getent group "$NEW_GROUP" | cut -f 3 -d ':')
        # Only do this at /home as other places are really scary
        # for instance if you are in VMWare and have the host file system
        # mounted in /mnt/hgfs
        sudo chown -R "$NEW_UID:$NEW_GID" --from "$OLD_UID" "$HOME_ROOT" || true
    fi
fi

SSHDIR="$HOME_ROOT/$NEW_USER/.ssh"
sudo -u "$NEW_USER" mkdir -p "$SSHDIR"
SSHDIR_KEYS="$SSHDIR/authorized_keys"
log_verbose "creating $SSHDIR_KEYS"
sudo -u "$NEW_USER" touch "$SSHDIR_KEYS"
NEW_AUTHORIZED_KEYS="$GIT_REPOS/$KEY_DIR/$USER_TYPE/$NEW_USER/ssh/authorized_keys"
if [ -e "$NEW_AUTHORIZED_KEYS" ]
then
    log_verbose "found $NEW_AUTHORIZED_KEYS"
    AUTHORIZED_KEYS="$(cat "$NEW_AUTHORIZED_KEYS")"
    if ! sudo -u "$NEW_USER" grep -q "$AUTHORIZED_KEYS" "$SSHDIR_KEYS"
    then
        log_verbose "Adding to $AUTHORIZED_KEYS to $SSHDIR_KEYS"
        sudo -u "$NEW_USER" tee -a "$SSHDIR_KEYS" > /dev/null <<<"$AUTHORIZED_KEYS"
        sudo -u "$NEW_USER" tee -a "$SSHDIR_KEYS" > /dev/null <<<"$AUTHORIZED_KEYS"
        sudo -u "$NEW_USER" chmod 600 "$SSHDIR_KEYS"
        sudo -u "$NEW_USER" chmod 700 "$SSHDIR"
    fi
fi

log_verbose Exiting add_user with code $?
