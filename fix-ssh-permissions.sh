#!/usr/bin/env bash
##
## fix the .ssh keys so that they are not too open
## Also adds an entry in .profile to do this all the time
## Because when you are symlinking from somewhere like dotfiles for .ssh/config
## for from veracrypt which uses FAT partitions without file permissions
## You have to make sure on every startup that the permissions are correct
##
## @author Rich Tong
## @returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdvw:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Fix ssh keys"
		echo "flags: -d debug, -h help"
		echo "       -w workspace directory"
		echo "for paths in \$PATHS"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	w)
		export WS_DIR="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-config.sh lib-util.sh

shift $((OPTIND - 1))

if [[ -z ${PATHS[*]} ]]; then
	PATHS=("$HOME/.ssh" "$HOME/.secret" "$HOME/.aws" "$HOME/vpn")
fi

log_verbose "recurse down into all ${PATHS[*]}"
for path in "${PATHS[@]}"; do
	log_verbose "closing up $path"
	# .ssh requires the parent not have write permissions
	# If there are symlinks, then follow them and change the app there
	# note that with gnu chmod this should correctly change everything
	# including the target of symlinked files
	# chmod -R og-rwx "$path"
	# use the -L so we look at the real types under the symlinks otherwise
	# symlinks will not match -type f
	if ! config_mark; then
		log_verbose "$(config_profile) does not have ssh fixes add them"
		# tighten up all directories use -exec and not -execdir because -execdir
		# gives you only file relative inside that directory
		# https://stackoverflow.com/questions/19126297/using-both-basename-and-full-path-in-find-exec
		# execdir is more secure since exec command can't see outside the
		# subdirectory but does not seem to work with chmod in .bash_profile not
		# sure why
		rel_path="$(realpath --relative-base-"$HOME")"
		config_add <<-EOF
			chmod og-w "\$HOME/$rel_path/.." "\$HOME/$rel_path"
			find -L "\$HOME/$rel_path" -type d -exec chmod og-rwx {} \;
			# closing up all it $rel_path children recursively note that -R does not follow symlinks properly so we run it ourselves
			find -L "\$HOME/$rel_path" -type f -exec chmod 600 {} \;
			# tighten up all keys to just readonly
			find -L "\$HOME/$rel_path" \( -name "*.id_rsa" -o -name "*.id_ed25519" \) -exec chmod 400 {} \;
		EOF
	fi
done

log_verbose "source $(config_profile)"
source_profile
