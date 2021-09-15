#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
#
## Creates keys if you need them in @rtong syntax
## This wraps the keys in the new bcrypt format using openssh version 6.5
## There is an option to rewrap keys as well
##
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR
OPTIND=1
KEY_TYPE="${KEY_TYPE:="ed25519"}"
# only used for rsa
BIT_LENGTH="${BIT_LENGTH:-4096}"
SECRET_USER="${SECRET_USER:-"$USER@tongfamily.com"}"
TARGET="${TARGET:="github.com"}"
SECRETS_DIR="${SECRETS_DIR:-"$HOME/.ssh"}"
SECRET_DATE="${SECRET_DATE:-"$(date +%Y-%m)"}"
ROUNDS="${ROUNDS:-256}"
FORCE="${FORCE:-false}"
while getopts "hdvu:t:k:b:a:s:y:i:fu:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Create ssh keys in proper filename and format

			usage: $SCRIPTNAME [flags...]

			flags: -d debug, -v verbose, -h help
			       -u user of the secrete for key (default: $SECRET_USER)
			       -t target site that will use the secret (default: $TARGET)
			       -k key type either rsa or ed25519 (default: $KEY_TYPE)
			       -b bit length for rsa only (default: $BIT_LENGTH)
			       -a number of rounds for pbkdf bcrypt (default: $ROUNDS)
			       -s directory where keys will be saved (default: $SECRETS_DIR)
			       -y date stampe for the key (default: $SECRET_DATE)
			       -i override key file name by (default: $SECRET_USER@$TARGET.$SECRET_DATE.id_$KEY_TYPE)
			       -f if a key exists already overwrite it (default: $FORCE)

			defaults would create a key file:
				$SECRET_USER-$TARGET.$SECRET_DATE.id_$KEY_TYPE
				$SECRET_USER-$TARGET.$SECRET_DATE.id_$KEY_TYPE.fingerprint
				$SECRET_USER-$TARGET.$SECRET_DATE.id_$KEY_TYPE.pub
		EOF

		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		FLAGS+=" -v "
		;;
	u)
		SECRET_USER="$OPTARG"
		;;
	s)
		SECRETS_DIR="$OPTARG"
		;;
	k)
		KEY_TYPE="$OPTARG"
		;;
	b)
		BIT_LENGTH="$OPTARG"
		;;
	a)
		ROUNDS="$OPTARG"
		;;
	t)
		TARGET="$OPTARG"
		;;
	i)
		KEY_FILE="$OPTARG"
		;;
	y)
		SECRET_DATE="$OPTARG"
		;;
	f)
		FORCE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# Need to reset key file fir there is a change
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND - 1))

mkdir -p "$SECRETS_DIR"
if ! pushd "$SECRETS_DIR" >/dev/null; then
	log_error 1 "no $SECRETS_DIR"
fi
log_verbose "using $SECRETS_DIR"

KEY_FILE=${KEY_FILE:-"$SECRET_USER-$TARGET.$SECRET_DATE.id_$KEY_TYPE"}
log_verbose key "$KEY_FILE"

if [[ -e $KEY_FILE ]] && ! $FORCE; then
	# return the existing keyfile name
	log_exit "$KEY_FILE exists use -f to overwrite returning the existing file"
fi

# need eval because $key_files has a file expansion
key_files="$(eval echo "$KEY_FILE"{,.pub,.fingerprint})"
log_verbose "creating $key_files"

# no quotes since this will become a set of files
if [[ -n $key_files ]]; then
	# shellcheck disable=SC2086
	rm -f $key_files
fi

# http://security.stackexchange.com/questions/39279/stronger-encryption-for-ssh-keys
# -o to use the new bcrypt format with -a 256 rounds
log_message enter a secure passphrase, the key is unrecoverable if you lose the phrase
log_message "make sure the comment in the key is the same as $KEY_FILE"
ssh-keygen -q -o -a "$ROUNDS" -b "$BIT_LENGTH" -t "$KEY_TYPE" -f "$KEY_FILE" -C "$KEY_FILE"
ssh-keygen -q -l -f "$KEY_FILE" >"$KEY_FILE.fingerprint"
log_verbose "creating fingerprint $KEY_FILE.fingerprint"

# https://askubuntu.com/questions/53553/how-do-i-retrieve-the-public-key-from-a-ssh-private-key
# note we need a space before KEYFILE as a separator from the public key
# Do not need this, the .pub includes the comment
# echo " $KEY_FILE" >> $KEY_FILE.pub
# log_verbose the comment is lost in the public key $KEY_FILE.pub as a note so is only in the private key so add manually

log_verbose "setting read only for $key_files"
if [[ -n $key_files ]]; then
	# shellcheck disable=SC2086
	chmod 444 $key_files
fi
chmod 400 "$KEY_FILE"
log_verbose "make sure the secret is tighter for $KEY_FILE"

log_verbose "$key_files created please put into a password manager and the passphrase as well!!!"

popd >/dev/null || true
