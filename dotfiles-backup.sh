#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Copies dotfiles into your personal repo on a per user basis
## Then relink them with dotfiles-stow.sh
## On other machines you can run them
##
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
DOTFILES_ROOT=${DOTFILES_ROOT:-"$(cd "$SCRIPT_DIR/../user/$USER/dotfiles" && pwd -P)"}
FORCE="${FORCE:-false}"
SOURCE_ROOT="${SOURCE_ROOT:-"$HOME"}"
SIMULATE="${SIMULATE:-false}"
while getopts "hdvs:t:x" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Backup the dotfiles that would be linked when doing dotfiles-stow.sh
			This goes through the stow directories and for every collision, it creates
			a backup file. If a backup file exists, it will increment and store it as
			.bak1, .bak2, ...

			    usage: $SCRIPTNAME [ flags ] [ directory of stow files ]

			    flags: -h help"
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
			           -s the root of your dotfiles you will back up (default: $SOURCE_ROOT)
			           -t stow files  directory of dotfiles (default: $DOTFILES_ROOT)
			           -x simulate what files would be moved (default: $SIMULATE)

		EOF
		exit
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	s)
		SOURCE_ROOT="$OPTARG"
		;;
	t)
		DOTFILES_ROOT="$OPTARG"
		;;
	x)
		SIMULATE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh


config_name="$(util_full_version)"
log_verbose "version is $config_name"
while [[ -n "$config_name" ]]; do
	dotfiles_dir="$DOTFILES_ROOT/$config_name"
	log_verbose "trying $dotfiles_dir"
	if [[ -e $dotfiles_dir ]]; then
		log_verbose "looking for files in $dotfiles_dir"
		# https://stackoverflow.com/questions/26381807/bash-loop-through-directory-including-hidden-file
		# the above does not handle strange files names well so use
		# https://github.com/koalaman/shellcheck/wiki/SC2044
		# instead and this requires bash 4.2
		shopt -s globstar nullglob
		# does not work with multiple levels, you get each directory level
		#for dotfile in "$dotfiles_dir"/**/*; do
		# does not handle spaces correctly in aths
		# for dotfile in $(find "$dotfiles_dir" -type f -print)
		# https://stackoverflow.com/questions/9612090/how-to-loop-through-file-names-returned-by-find
		find "$dotfiles_dir" -type f -print0 |
			while IFS= read -r -d '' dotfile; do
				# https://stackoverflow.com/questions/16623835/remove-a-fixed-prefix-suffix-from-a-string-in-bash#16623897
				source_file="$SOURCE_ROOT${dotfile#"$dotfiles_dir"}"
				log_verbose "found $dotfile"
				if [[ ! -e $source_file ]]; then
					log_verbose "no $source_file nothing to backup"
					continue
				fi
				# move symlinks too as they could be hand done
				# if [[ -L $source_file ]]; then
				# 	log_verbose "$source_file is already symlinked skipping"
				# 	continue
				# fi
				log_verbose "found $source_file finding a free backup location"
				count=0
				backup="$source_file.bak"
				while true; do
					log_verbose "looking for $backup"

					if [[ ! -e $backup ]]; then
						log_verbose "no $backup found"
						log_verbose "move $source_file to $backup"
						if ! $SIMULATE; then
							#read -p "press enter to continue" </dev/tty
							mv "$source_file" "$backup"
							log_verbose "no $backup present so moved $source_file there"
						fi
						break
					fi

					log_verbose "existing $backup found"
					if cmp -s "$source_file" "$backup"; then
						log_verbose "$source_file already in $backup; rm it"
						if ! $SIMULATE; then
							rm "$source_file"
							log_verbose "rm $source_file already backed up as $backup"
						fi
						break
					fi

					log_verbose "found different $backup looking for an empty one"
					backup="${backup%.bak*}.bak.$((++count))"
				done
			done
	fi

	# if there are no more periods we have processed the last one
	# we need escape the . otherwise it means wildcard
	if [[ ! $config_name =~ \. ]]; then
		if [[ $config_name == common ]]; then
			log_verbose "tried common so now we are really done"
			break
		fi
		log_verbose found the last variant now check common
		config_name=common
		continue
	fi
	# remove one set of names from the end of the string
	config_name="${config_name%.*}"
done
