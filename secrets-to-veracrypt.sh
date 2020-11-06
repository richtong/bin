#!/usr/bin/env bash
##
## Move the secrets in .ssh into an vault, this can then be
## symlinked by secrets-stow.sh
##
##
## Uses Dropbox or other scheme to copy the Veracrypt vault around
##
## This wraps the keys in the new bcrypt format using openssh version 6.5
##
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1
FORCE="${FORCE:-false}"
FLAGS="${FLAGS:-""}"
if [[ $OSTYPE =~ darwin ]]; then
	TARGET_DIR="${TARGET_DIR:-"/Volumes"}"
else
	TARGET_DIR="${TARGET_DIR:-"/media"}"
fi
TARGET="${TARGET:-"$TARGET_DIR/$USER.vc/secrets/.ssh/common"}"
SECRETS="${SECRETS:-"$HOME/.ssh"}"

while getopts "hdvft:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Move real ssh keys into a stow location you can use secrets-stow.sh to symlink
			back

			Usage: $SCRIPTNAME [flags] [keys...]
			flags:  -d debug, -v verbose, -h help
			        -t move secrets to this directory for the secrets (default: $TARGET)

			positionals: list of keys to create normally in the format
			        defaults are all the real .ssh keys in $SECRETS

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
	f)
		FORCE=true
		FLAGS+=" -f "
		;;
	t)
		TARGET="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

shift $((OPTIND - 1))

if (($# > 0)); then
	log_verbose "using positionals $*"
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	SECRETS=("$@")
fi

if [[ ! -e $TARGET ]]; then
	log_warning "No Vault dir did you sync"
fi

mkdir -p "$TARGET"

log_verbose "look for real id_rsa and id_ed25519 files in ${SECRETS[*]}"
# shellcheck disable=SC2044
for key in $(find "${SECRETS[@]}" -type f -name "*.id_rsa" -o -name "*.id_ed25519"); do
	log_verbose "found $key"
	# note the $FORCE override the interactive -i
	# shellcheck disable=SC2086
	cp -i $FLAGS "$key" "$TARGET"
	log_verbose "copied $key to $TARGET"
	if $FORCE; then
		# shellcheck disable=SC2086
		rm $FLAGS "$key"
		log_verbose "removed $key"
	fi
done
