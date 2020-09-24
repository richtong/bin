#!/usr/bin/env bash
## ## Mounts our ai0 the main server in $WS_DIR
## https://blog.sleeplessbeastie.eu/2013/03/27/how-to-easily-access-files-over-ssh-protocol/
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
# this replace set -e by running exit on any error use for bashdb
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# the local works for sure rmeotel but no local will fail
SERVER="${SERVER:-ai0}"
# Note we do not want a leading slash in the mount names
MOUNTS="${MOUNTS:-"data "home/$USER""}"
REMOTE_MOUNTPOINT="${REMOTE_MOUNTPOINT:-/}"
WS_DIR="${WS_DIR:-"$HOME/ws"}"
LOCAL_MOUNTPOINT="${LOCAL_MOUNTPOINT:-"$HOME/mnt"}"
UIDFILE="${UIDFILE:-"$HOME/ws/git/src/infra/etc/$SERVER.uidfile.txt"}"
GIDFILE="${GIDFILE:-"$HOME/ws/git/src/infra/etc/$SERVER.gidfile.txt"}"
FORCE=false
RETRIES=${RETRIES:-5}
OPTIND=1
while getopts "hdvs:r:l:u:g:fr:" opt
do
    case "$opt" in
        h)
            echo Mount main file server with sshfs in workspace
            echo usage: $SCRIPTNAME [ flags ] mounts
            echo
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -s file server (default: $SERVER)"
            echo "       -r remote mount point (default : $REMOTE_MOUNTPOINT)"
            echo "       -f force delete the destination (default: $FORCE)"
            echo "       -n retry the sshfs mount this man times (default: $RETRIES)"
            echo
            echo "these flags will be preceded by the ws location"
            echo "       -l local mount point (default : $LOCAL_MOUNTPOINT)"
            echo "       -u uidfile maps local user to remote uid (default: $UIDFILE)"
            echo "       -g gidfile maps local groups to remote gid (default: $GIDFILE)"
            echo
            echo "You can add this command to the path but you must make sure"
            echo "the $SERVER is visible for this to work"
            echo
            echo "The mount destination is the root name of the mounts"
            echo "positionals: directories to mount from local to user"
            echo "the mount names snould not have a leading slash, they are"
            echo "relative to the remote and local mount points"
            echo "       defaults: $MOUNTS"
            echo
            exit
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        s)
            SERVER="$OPTARG"
            ;;
        r)
            REMOTE_MOUNTPOINT="$OPTARG"
            ;;
        l)
            LOCAL_MOUNTPOINT="$OPTARG"
            ;;
        u)
            UIDFILE="$OPTARG"
            ;;
        g)
            GIDFILE="$OPTARG"
            ;;
        f)
            FORCE=true
            ;;
        r)
            RETRIES="$OPTARG"
            ;;
    esac
done
# must be here after DEBUGGING set
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
# lib-network needs lib-install.sh
source_lib lib-util.sh lib-install.sh lib-network.sh
shift $((OPTIND-1))
if [[ ! $OSTYPE =~ linux ]]
then
    log_warning only tested on linux
fi
log_verbose checking for sshfs
if ! command -v sshfs >/dev/null
then
    "$SCRIPT_DIR/install-sshfs.sh"
fi

# https://stackoverflow.com/questions/34360943/check-if-ssh-connection-is-possible-when-it-needs-a-password
log_verbose trying to ssh into $SERVER
if ! ssh -q "$SERVER" exit
then
    log_verbose could not ssh into $SERVER
    found=false
    stripped="$(remove_local "$SERVER")"
    # use the r suffix as a convention for remote access in .ssh/config so
    # ai0r means remote connect to ai0
    for host in "$(add_local "$SERVER")" "$stripped" "${stripped}r"
    do
        log_verbose trying $host
        if ssh -q "$host" exit
        then
            log_verbose found $host alive and reset set as SERVER
            SERVER="$host"
            found=true
            break
        fi
    done
    if ! $found
    then
        log_exit 2 "$SERVER could not reach with ssh"
    fi
fi
log_verbose ssh into $SERVER suceeeded

log_verbose build the sshfs statement flags
flags=" -C -o reconnect,ServerAliveInterval=30 "
if [[ -e $UIDFILE ]]
then
    # do not use quotes as this fails in the script
    # even though this means the file names cannot contain spaces
    log_verbose found $UIDFILE using it for mapping
    log_verbose make sure $UIDFILE is read only
    sudo chmod 444 "$UIDFILE"
    flags+=" -o idmap=file,nomap=ignore,uidfile=$UIDFILE "
    if [[ -e $GIDFILE ]]
    then
        log_verbose map gids with $GIDFILE
        flags+=" -o gidfile=$GIDFILE "
        log_verbose make sure $GIDFILE is read only
        sudo chmod 444 "$GIDFILE"
    fi
fi

log_verbose will run sshfs with $flags

for mount in $MOUNTS
do
    # https://blog.sleeplessbeastie.eu/2013/03/27/how-to-easily-access-files-over-ssh-protocol/
    # -C compression
    # -o options
    #    reconnect
    #    ServerAliveInterval=30
    #    idmap=file use the files
    #      uidfile=
    #      gidfile=
    # note the options come after the src and dest
    log_verbose dest is $LOCAL_MOUNTPOINT/$mount
    # -m means no parts need to exist
    dest="$(readlink -m "$LOCAL_MOUNTPOINT/${mount%%/*}")"
    src="$SERVER:$(readlink -m "$REMOTE_MOUNTPOINT/$mount")"
    if $FORCE
    then
        log_verbose force remove $dest
        sudo rm "$dest"
    fi
    log_verbose making $dest
    mkdir -p "$dest"
    if ! dir_empty "$dest"
    then
        log_warning $dest not empty set FORCE to delete
        continue
    fi
    log_verbose $dest is empty so we can mount there

    # -C Compression
    # -o reconnect,ServerAliveInterval=30 for fragile network connections
    # -o idmap use the $UIDFILE and $GIDFILE to map local user and group names
    # to remote uid and gid
    # -o nomap=ignore mwans if the mapping doesn't exist do not error out

    log_verbose if sshfs fails wait a bit and retry as ssh address resolution is flakey
    for ((i = 0; i < $RETRIES; i++))
    do
        log_verbose running sshfs "$src" "$dest" $flags
        if sshfs "$src" "$dest" $flags
        then
            log_verbose "sshfs session created for from $src mounted on $dest"
            break
        fi
        log_verbose sshfs returned $?
        sleep 5
    done
done
