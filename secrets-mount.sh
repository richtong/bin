#!/usr/bin/env bash
##
## install the private folder of secrets from Dropbox to Veracrypt volume
## This is much simpler than the ecryptfs and dmg version as we do not need
## two level of mounting.
##
## In that version, ecryptfs with needs two levels of mounting from
## ~/Dropbox/.Private to ~/Dropbox.Private and then we would copy that to
## ~/.Private mounted as ~/Private
## In the old Mac version we just have a Dropbox with a Private dmg and a one level mounting
##
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
FILE_SHARING_DIR="${FILE_SHARING_DIR:-"$HOME/Dropbox"}"
MANUALMOUNT="${MANUALMOUNT:-false}"
if [[ $OSTYPE =~ darwin ]]; then
	SECRETS_ROOT_DIR="${SECRETS_ROOT_DIR:-"/Volumes"}"
else
	SECRETS_ROOT_DIR="${SECRETS_ROOT_DIR:-"/media"}"
fi
SECRET_USER="${SECRET_USER:-"$USER"}"
while getopts "hdvl:u:m:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Install the private directories where secrets live
			usage: $SCRIPTNAME [ flags ] directory

			flags: -d debug, -v verbose, -h help
			       -l location of file sharing service directories (Default: $FILE_SHARING_DIR)
			       -u Name of the secret user (default: $SECRET_USER)
			       -m Do not automount, each time you manually mount the volume (default: $MANUALMOUNT)

			positionals:
			       The directory where secrets are mounted (default: $SECRETS_ROOT_DIR)


		EOF

		exit
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	l)
		FILE_SHARING_DIR="$OPTARG"
		;;
	m)
		MANUALMOUNT=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND - 1))

if (($# > 0)); then
	SECRETS_ROOT_DIR="$1"
fi

ENCRYPTED_BASENAME="${ENCRYPTED_BASENAME:-$SECRET_USER.vc}"
log_verbose "looking $ENCRYPTED_BASENAME"

ENCRYPTED_MOUNTPOINT="$SECRETS_ROOT_DIR/$ENCRYPTED_BASENAME"
log_verbose "secrets will be mounted in $ENCRYPTED_MOUNTPOINT"

log_verbose On linux, use Veracrypt on Dropbox or other sync mounts to /media
log_verbose On Mac, use Veracrypt on Dropbox or other sync mounts to /Volumes
ENCRYPTED_PATH="$FILE_SHARING_DIR/$ENCRYPTED_BASENAME"
log_verbose "find the $ENCRYPTED_PATH and mount it at $ENCRYPTED_MOUNTPOINT"

if [[ ! -e $ENCRYPTED_PATH ]]; then
	log_verbose "could not find $ENCRYPTED_PATH expanding search to all other locations"
	# https://unix.stackexchange.com/questions/60849/find-files-in-multiple-folder-names
	# Note there may be spaces in the names so go through each one
	# Debugging does not work so need to turn tracing off
	# https://stackoverflow.com/questions/1521462/looping-through-the-content-of-a-file-in-bash
	# note we use fd 10 so we do not collide with stdin
	# Always -r raw read http://wiki.bash-hackers.org/commands/builtin/read

	log_verbose look for file sharing drive either Dropbox, Google Drive or OneDrive
	log_verbose "$FILE_SHARING_DIR does not exist search for other file sharing services"
	FILE_SHARING_DIRS="$("$SCRIPT_DIR/secrets-find-file-sharing.sh")"
	if [[ -z $FILE_SHARING_DIRS ]]; then
		log_error 2 "no $ENCRYPTED_BASENAME found in $FILE_SHARING_DIRS please sync into them"
	fi
	log_verbose "found $FILE_SHARING_DIRS as possible locations of encrypted file"
	while read -r -u 10 path; do
		log_verbose "looking in $path for $ENCRYPTED_BASENAME"
		ENCRYPTED_PATH="$(find "$path" -maxdepth 3 -name "$ENCRYPTED_BASENAME" -print -quit)"
		log_verbose "found $ENCRYPTED_BASENAME in ${ENCRYPTED_PATH[*]}"
		if [[ -n ${ENCRYPTED_PATH-} ]]; then
			log_verbose "$ENCRYPTED_PATH found"
			break
		fi
	done 10<<<"$FILE_SHARING_DIRS"
fi

if [[ -z ${ENCRYPTED_PATH-} ]]; then
	log_error 2 "could not find any locations for $ENCRYPTED_BASENAME in ${FILE_SHARING_SERVERS[*]}"
fi

log_verbose "looking for $ENCRYPTED_PATH and mount at $ENCRYPTED_MOUNTPOINT"
"$SCRIPT_DIR/veracrypt-mount.sh" "$ENCRYPTED_PATH" "$ENCRYPTED_MOUNTPOINT"

log_verbose "look for ssh on $ENCRYPTED_MOUNTPOINT"
if [[ ! -e "$ENCRYPTED_MOUNTPOINT/secrets" ]]; then
	log_error 3 "no files in $ENCRYPTED_MOUNTPOINT did you run the file sharing service sync"
fi

log_verbose make sure our permissions are closed
"$SCRIPT_DIR/fix-ssh-permissions.sh" "$ENCRYPTED_MOUNTPOINT/secrets"
