#!/usr/bin/env bash
##
## Stow secrets from encrypted directory to ssh and other places
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
TARGET="${TARGET:-"$HOME/.ssh"}"
SECRETS_DIR="${SECRETS_DIR:-"$HOME/.secret"}"
if [[ ! -v SECRETS ]]; then
	SECRETS=("$HOME/.ssh" "$HOME/.aws" "$HOME/vpn")
fi
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvs:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Symlink from the secrets directory

			    usage: $SCRIPTNAME [ flags ] [secrets-directory ]
			    flags: -d debug, -v verbose, -h help"
			           -s location of secrets directory (default: $SECRETS_DIR)
			    positionals:
			           targets for secrets assumes the file names are the same
			           (default: ${SECRETS[*]})

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

if (($# > 0)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	SECRETS=("$@")
fi
"$SCRIPT_DIR/stow-all.sh" -s "$SECRETS_DIR" "${SECRETS[@]}"

log_verbose "close up the secrets permissions"
chmod -R go-rwx "${SECRETS[@]}"
