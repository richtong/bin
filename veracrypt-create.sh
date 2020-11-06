#!/usr/bin/env bash
##
## Creates a VeraCrypt hidden volume
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
export FLAGS="${FLAGS:-""}"
SECRET_USER="${SECRET_USER:-"$USER"}"
SECRET_DIR="${SECRET_DIR:-"$HOME/Dropbox"}"
SECRET_MOUNTPOINT_DIR="${SECRET_MOUNTPOINT_DIR:-"/media"}"
OPTIONS="${OPTIONS:-(--keyfiles "" --encryption=(Serpent(Twofish(AES)) --hash=sha=512 --pim=0 --random-source=/dev/urandom --filesystem=fat )}"
SIZE="${SIZE:-32}"
OPTIND=1
while getopts "hdvu:fs:o:z:m:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Create a Veracrypt hidden volume for your secrets at $HOME/Dropbox/$SECRET_USER
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help
			           -u user whose secrets are being saved (default: $SECRET_USER)
			           -f force the deletion of existing volumes (default: $FORCE)
			           -s directory for the new volume (default: $SECRET_DIR)
			           -o options for VeraCrypt (default: $OPTIONS)
			           -z siZe in MB of the volume (default: $SIZE)
			           -m mountpoint for secrets (default: $SECRET_MOUNTPOINT_DIR)
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
	u)
		SECRET_USER="$OPTARG"
		;;
	f)
		FORCE=true
		;;
	s)
		SECRET_DIR="$OPTARG"
		;;
	o)
		OPTIONS="$OPTARG"
		;;
	z)
		SIZE="$OPTARG"
		;;
	m)
		SECRET_MOUNTPOINT="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-fs.sh
shift $((OPTIND - 1))

"$SCRIPT_DIR/install-veracrypt.sh"

if [[ $OSTYPE =~ darwin ]]; then
	log_verbose assume veracrypt is installed in /Applications/VeraCrypt.app
	SECRET_MOUNTPOINT_DIR="/Volumes"
	log_verbose on Mac adjust veracrypt executable and mountpoint directory
else
	SECRET_MOUNTPOINT_DIR="/media"
fi

if [[ $SECRET_DIR =~ Dropbox ]]; then
	"$SCRIPT_DIR/install-dropbox.sh"
	if ! dropbox_find; then
		log_error 1 "no Dropbox folders found did you install and sync?"
	fi
fi

# .tc is truecrypt and .hc is hidden container
SECRET_VOL="$SECRET_DIR/$SECRET_USER.vc"

if [[ -e $SECRET_VOL ]]; then
	if ! $FORCE; then
		log_error 2 "$SECRET_VOL exists use -f to recreate it"
	fi
	rm "$SECRET_VOL"
fi

# https://veracrypt.codeplex.com/wikipage?title=Command%20Line%20Usage
# https://github.com/veracrypt/VeraCrypt/issues/137
log_verbose create the outer volume and enter a passphrase for it
# make sure outer is twice the size as the hidden looks like noise in
# shellcheck disable=SC2086
veracrypt -t --create $OPTIONS --protect-hidden=yes --volume-type=normal --size $((SIZE * 2))M "$SECRET_VOL"
log_verbose create the inner hidden volume and enter passphrase
# shellcheck disable=SC2086
veracrypt -t --create $OPTIONS --volume-type=hidden --size "${SIZE}M" "$SECRET_VOL"

# https://help.ubuntu.com/community/TruecryptHiddenVolume
log_verbose "mounting outer volume at /media/$SECRET_USER.outer"
log_verbose add random data to the outer volume to preserve deniability
secret_mountpoint="$SECRET_MOUNTPOINT/$SECRET_USER"
secret_mountpoint_outer="$secret_mountpoint.outer"
mkdir -p "secret_mountpoint_outer"
if ! veracrypt -tl "$secret_mountpoint_outer" >/dev/null 2>&1; then
	log_verbose "mounting $secret_mountpoint_outer"
	log_verbose enter the correct passphrase for it
	veracrypt -t --pim=0 --k "" --protect-hidden=yes \
		"$SECRET_VOL" "$secret_mountpoint_outer"
else
	log_warning "the volume already mounted at $secret_mountpoint_outer"
fi

# https://unix.stackexchange.com/questions/33629/how-can-i-populate-a-file-with-random-data
log_verbose create some random data on outer volume
cp "$SOURCE_DIR/README"* "$secret_mountpoint_outer"

if ! veracrypt -tl "$secret_mountpoint" >/dev/null 2>&1; then
	log_verbose "mounting $secret_mountpoint"
	log_verbose now enter the password for the hidden volume
	veracrypt -t --pim=0 -k "" --protect-hidden=no \
		"$SECRET_VOL" "$SECRET_MOUNTPOINT/$SECRET_USER"
fi

"$SCRIPT_DIR/veracrypt-automount.sh"
