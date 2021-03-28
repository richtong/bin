#!/usr/bin/env bash
##
## Install iterm2 and profiles
##
# https://iterm2.com/documentation-dynamic-profiles.html
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
ITERM2_PATH="${ITERM2_PATH:-"Library/Application Support/iTerm2/DynamicProfiles"}"
ITERM2_FILE="${ITERM2_FILE:-"iterm2.profiles.json"}"
ITERM2_PROFILE_DST="${ITERM2_PROFILE_DST:-"$HOME/$ITERM2_PATH/$ITERM2_FILE"}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvp:" opt; do
	case "$opt" in
	h)
		cat <<EOF
Installs iTerm2 and dynamic profiles
which may be in JSON or XML property lists or Plists
Make sure this is formatted properly with a guid and name for each 

	usage: $SCRIPTNAME [ flags ]
	flags: -d debug, -v verbose, -h help"
		   -p iterm2 profile (default: $ITERM2_SRC)
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
	p)
		ITERM2_PROFILE_SRC="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-config.sh lib-mac.sh lib-install.sh lib-util.sh

# since this uses WS_DIR need to have it run after include
ITERM2_PROFILE_SRC="${ITERM2_PROFILE_SRC:-"$WS_DIR/git/src/user/$USER/dotfiles/macos/$ITERM2_PATH/$ITERM2_FILE"}"


if ! in_os mac; then
	log_exit "mac only"
fi

brew_install iterm2

log_verbose "making $ITERM2_PATH"
mkdir -p "$HOME/$ITERM2_PATH"
log_verbose "install dynamic profiles"
if [[ -e $ITERM2_PROFILE_SRC ]] && [[ ! -e $ITERM2_PROFILE_DST ]]; then
	log_verbose "symlink $ITERM2_PROFILE_SRC to $ITERM2_PROFILE_DST"
	# generate a guid with uuidgen
	ln -s "$(realpath --relative-to="${ITERM2_PROFILE_DST%/*}" "$ITERM2_PROFILE_SRC")" "$ITERM2_PROFILE_DST"
fi

log_verbose "install shell integrations"
curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

if ! config_mark; then
	# shellcheck disable=SC2016
	config_add <<-'EOF'
	# shellcheck disable=SC2015,SC1090
	[[ -e $HOME/.iterm2_shell_integration.bash ]] && source "$HOME/.iterm2_shell_integration.bash" || true
	EOF
fi
