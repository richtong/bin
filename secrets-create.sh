#!/usr/bin/env bash
##
## Creates a new secret in the secret location and creates
## a symlink to it in the target directory
## The trick here is the secrets volume
## has the same directory layout as for the target so that this
## a simple stow can work later
## So when we create the secret we need to do enough directory creation to make
## this true
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
if [[ $OSTYPE =~ darwin ]]; then
	SECRETS_DIR_ROOT="${SECRETS_DIR_ROOT:-"/Volumes"}"
else
	SECRETS_DIR_ROOT="${SECRETS_DIR_ROOT:-"/media"}"
fi
SECRETS_DIR="${SECRETS_DIR:-"$SECRETS_DIR_ROOT/$USER.vc/secrets"}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvs:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Copy in a new secret into the secret volume and then symlink from target
			    usage: $SCRIPTNAME [ flags ] location_of_secrets $HOME...
			    flags: -d debug, -v verbose, -h help"
			           -s location of source of secrets directory (default: $SECRETS_DIR)
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
	s)
		SECRETS_DIR="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-stow.sh
shift $((OPTIND - 1))

log_verbose "putting secrets in $SECRETS_DIR"

# need to use readlink to handle symlinks
home="$(readlink -f "$HOME")"
log_verbose "the real home is $home"

for secret in "$@"; do
	if [[ ! -e $secret ]]; then
		log_verbose "$secret not found"
	fi
	# https://unix.stackexchange.com/questions/6435/how-to-check-if-pwd-is-a-subdirectory-of-a-given-path
	# https://stackoverflow.com/questions/4132510/how-to-test-that-a-variable-starts-with-a-string-in-bash
	if [[ ! $(readlink -f "$secret") =~ ^$home ]]; then
		log_verbose "$secret is not contained in $home skipping"
		continue
	fi
	# https://unix.stackexchange.com/questions/85060/getting-relative-links-between-two-paths
	# now just get the relative path and we will make that in the secrets
	secret_target="$SECRETS_DIR/$(realpath --relative-to="$home" "$secret")"
	log_verbose "put the secret into $secret_target first mkdir the entire path"
	mkdir -p "$(dirname "$secret_target")"
	log_verbose "now move the secret from $secret to $secret_target"
	mv "$secret" "$secret_target"
	log_verbose and symlink from the "$secret_target" to "$secret"
	ln -s "$secret_target" "$secret"
done
