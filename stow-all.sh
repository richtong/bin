#!/usr/bin/env bash
##
##@author Rich Tong
##@returns 0 on success
## Stow secrets from encrypted directory to
## This is layered so it stores from the minor to major versions
## Using packages of the form os.major.minor
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
SOURCE_DIR="${SOURCE_DIR:-"$HOME/.secrets"}"
TARGETS="${TARGETS:-($HOME $HOME/.ssh $HOME/vpn)}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvs:" opt; do
	case "$opt" in
	h)
		cat <<EOF
Symlink from a special source directory to a target
usage: $SCRIPTNAME [ flags ] [source directory ]
flags: -d debug, -v verbose, -h help"
	   -s location of source directory (default: $SOURCE_DIR)
positionals:
	   targets for linking assumes the file names are the same in both
	   (default: $TARGETS)
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
		SOURCE_DIR="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh

shift $((OPTIND - 1))
if (($# > 0)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	TARGETS=("$@")
fi

package_install stow

# handles existence of the package and also error
# usage: stow_if package stow_dir target
stow_if() {
	if (($# < 1)); then return 1; fi
	local package="$1"
	local stow_dir="${2:-"."}"
	local target="${3:-".."}"
	log_verbose "looking $stow_dir"
	if [[ ! -e $stow_dir/$package ]]; then
		log_verbose "$package does not exist"
		return
	fi
	log_verbose "$stow_dir/$package exists stowing to $target with --defer"
	if ! stow --defer=".*" -d "$stow_dir" -t "$target" "$package"; then
		log_verbose "error most likely an existing real file in $target remove to you should backup $target to $target.bak and try again"
	fi
}

# note that STOW_DIR is the external stow uses so -d and this are redundent safety
# config_path returns the deepest existing path of os/major/minor release/...
# Note we use dashes instead of true directories since stow
# is recursive
mkdir -p "$SOURCE_DIR"
log_verbose "getting files from $SOURCE_DIR"
full_version_name="$(util_full_version)"
for target in "${TARGETS[@]}"; do
	target="$(readlink -f "$target")"
	log_verbose "processing $target"
	mkdir -p "$target"
	if [[ $target == "$HOME" ]]; then
		export source=.
		log_verbose special case for the home dir to dotfiles
	else
		source="$(basename "$target")"
		export source
	fi
	STOW_DIR="$SOURCE_DIR/$source"
	log_verbose "stow $STOW_DIR into $target"
	# do-while loop
	# https://stackoverflow.com/questions/16489809/emulating-a-do-while-loop-in-bash
	config_name="$full_version_name"
	# This non zero check guards against null full_version_names
	while [[ -n "$config_name" ]]; do
		log_verbose "trying to stow $config_name"
		# dir structure is ./, ./os, ./os.major, ./os.major.minor...
		# --defer means do not mind collisions
		# -d means use this as the stow source directory
		# So each directory in turn adds, we go from most detail to leaset
		stow_if "$config_name" "$STOW_DIR" "$target"

		# if there are no more periods we have processed the last one
		# we need escape the . otherwise it means wildcard
		if [[ ! $config_name =~ \. ]]; then
			break
		fi
		# remove one set of names from the end of the string
		config_name="${config_name%.*}"
	done
	log_verbose "do common last so deeper versions can override"
	log_verbose "STOW_DIR is $STOW_DIR and stowing common deferring if they already exist"
	stow_if common "$STOW_DIR" "$target"
done
