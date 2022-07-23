#!/usr/bin/env bash
##
## install the private folder of secrets from ecryptfs or MacOS
## https://www.npmjs.com/package/onepass-cli for npm package
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
FILE_SHARING_SERVICES="${FILE_SHARING_SERVICES:-(Dropbox "Google Drive" OneDrive)}"
while getopts "hdvl:s:" opt; do
	case "$opt" in
	h)
		echo Install the private directories where secrets live
		echo "usage: $SCRIPTNAME [ flags ]"
		echo
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -l location of file sharing service directories (Default: $FILE_SHARING_DIR)"
		echo "       -s Will automatically search for the location different file sharing services (default $FILE_SHARING_SERVICES)"
		echo "if the default does not exist"
		echo "stdout: the path to the encrypted directory"
		exit 0
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
	s)
		FILE_SHARING_SERVICES="$OPTARG"
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

log_verbose look for file sharing drive either Dropbox, Google Drive or OneDrive
if [[ ! -e $FILE_SHARING_DIR ]]; then
	log_verbose "$FILE_SHARING_DIR does not exist search for other file sharing services"
	FILE_SHARING_DIRS=$("$SCRIPT_DIR/secrets-find-file-sharing.sh" "${FILE_SHARING_SERVICES[*]}")
fi

log_verbose find the ENCRYPTED_PATH and mount it at ENCRYPTED_MOUNTPOINT
log_verbose On linux, use ecryptfs encrypted folder on Dropbox or other sync
log_verbose On the mac we just have one step, ~/Dropbox/Private.dmg mounts
log_verbose at /Volumes/Private and this automounts, with Linux we have
log_verbose two steps, first ~/Dropbox/.Private mounts in ~/Dropbox.Private
log_verbose "then setup-ecryptfs-private create ~/.Private mounting into ~/Private"
log_verbose "then ~/Dropbox.Private copies into ~/Private so we do not"
log_verbose need to automount ~/Dropbox.Private or remember a passphrase
if [[ $OSTYPE =~ darwin ]]; then
	ENCRYPTED_BASENAME="${ENCRYPTED_BASENAME:-Private.dmg}"
	ENCRYPTED_MOUNTPOINT=${ENCRYPTED_MOUNTPOINT:-/Volumes/Private}
	PRIVATE_MOUNTPOINT="${PRIVATE_MOUNTPOINT:-"$ENCRYPTED_MOUNTPOINT"}"
	log_verbose with Mac, the Privcte mount point and encrypted point are the same
else
	ENCRYPTED_BASENAME="${ENCRYPTED_BASENAME:-".Private"}"
	ENCRYPTED_MOUNTPOINT="${ENCRYPTED_MOUNTPOINT:-"$FILE_SHARING_DIR.Private"}"
	PRIVATE_MOUNTPOINT="${PRIVATE_MOUNTPOINT:-"$HOME/Private"}"
fi

log_verbose now looking for path to the encrypted directory with ssh keys

ENCRYPTED_PATH="$FILE_SHARING_DIR/$ENCRYPTED_BASENAME"
log_verbose "looking for $ENCRYPTED_PATH and mount at $ENCRYPTED_MOUNTPOINT"
# note this works when $SHARING is multiple directories
# https://alvinalexander.com/blog/post/linux-unix/find-how-search-multiple-folders-directories-unix
# only finds the first occurance
if [[ ! -e $ENCRYPTED_PATH ]]; then
	ENCRYPTED_PATHS=$(find "$FILE_SHARING_SERVICES" -maxdepth 3 -name "$ENCRYPTED_BASENAME" -print -quit)
	log_verbose "could not find $ENCRYPTED_PATH expanding search to all $FILE_SHARING_DIRS"

	if [[ -z ${ENCRYPTED_PATHS-} ]]; then
		log_verbose "could not find any locations for $ENCRYPTED_BASENAME"
		if [[ $OSTYPE =~ darwin ]]; then
			log_warning "did not find any $ENCRYPTED_BASENAME in $FILE_SHARING_DIRS create a $ENCRYPTED_BASENAME  from ~/.ssh"
			log_verbose "pick the first quoted string in $FILE_SHARING_DIRS"
			# converts this into an array https://stackoverflow.com/questions/35636323/extracting-a-string-between-two-quotes-in-bash
			FILE_SHARING_DIR=$FILE_SHARING_DIRS
			# http://www.theinstructional.com/guides/disk-management-from-the-command-line-part-3
			# Then just referring to the DIR gives you the first element so that is
			# the same as ${DIR[0]}
			if ! pushd "$(dirname "${FILE_SHARING_DIR[0]}")" >/dev/null; then
				log_verbose "no ${FILE_SHARING_DIR[0]}"
			fi
			# when creating the dmg label with the basename minus the .extension
			# https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bashj
			hdiutil create "$ENCRYPTED_BASENAME" -volname "${ENCRYPTED_BASENAME%.*}" \
				-srcfolder "$HOME/.ssh" \
				-size 32 -encryption AES-256 -stdinpass -fs JHFS+
			log_error 2 "mount and edit as needed then rerun $SCRIPTNAME"
			popd >/dev/null || true
		else
			log_error 3 "no $PRIVATE found in $SHARING you need to copy .ssh into $PRIVATE in $SHARING"
		fi
	fi
	log_verbose "found valid $ENCRYPTED_PATHS pick the first one"
	ENCRYPTED_PATH=$ENCRYPTED_PATHS
fi

log_verbose "looking for ${ENCRYPTED_PATH[*]} and mount at $ENCRYPTED_MOUNTPOINT"

if [[ $OSTYPE =~ darwin ]]; then
	if [[ ! -e $ENCRYPTED_MOUNTPOINT ]]; then
		log_verbose "attaching ${ENCRYPTED_PATH[*]} to $ENCRYPTED_MOUNTPOINT"
		hdiutil attach "${ENCRYPTED_PATH[0]}"
	else
		log_warning "$ENCRYPTED_MOUNTPOINT volume already exists using it instead"
	fi
	log_assert "[[ -e $ENCRYPTED_MOUNTPOINT ]]" "$ENCRYPTED_MOUNTPOINT exists"
else

	log_verbose "$PRIVATE_MOUNTPOINT is up so now mount ${ENCRYPTED_PATH[*]} at $ENCRYPTED_MOUNTPOINT"
	"$SCRIPT_DIR/mount-ecryptfs.sh" "$ENCRYPTED_MOUNTPOINT"

	log_verbose "look for ssh on $ENCRYPTED_MOUNTPOINT"
	if [[ ! -e "$ENCRYPTED_MOUNTPOINT/ssh" ]]; then
		log_error 3 "no files in $ENCRYPTED_MOUNTPOINT did you run the file sharing service sync"
	fi

fi

# We copy because Private is automounted and we do not need Dropbox all the time
log_verbose "only copy $USER directories"
if [[ $ENCRYPTED_MOUNTPOINT == "$PRIVATE_MOUNTPOINT" ]]; then
	echo "$ENCRYPTED_PATH"
	log_exit "$ENCRYPTED_MOUNTPOINT sams as $PRIVATE_MOUNTPOINT"
fi

cp -a "$ENCRYPTED_MOUNTPOINT/"* "$PRIVATE_MOUNTPOINT"

log_verbose make sure our permissions are closed
"$SCRIPT_DIR/fix-ssh-permissions.sh" "$PRIVATE_MOUNTPOINT/ssh"

echo "$ENCRYPTED_PATH"
