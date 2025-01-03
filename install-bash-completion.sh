#!/usr/bin/env bash
##
## Install bash completions on Mac
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install bask completion
			flags: -d debug, -v verbose, -h help
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh lib-config.sh lib-version-compare.sh
shift $((OPTIND - 1))

# these are just for homebrew completions for the brew command
# there may be others in bash_completion.d that are also sourced
# https://julienharbulot.com/bash-completion-tutorial.html
# completions should go into .bashrc as they need to reinitialized with
# every interactive bash invocation
# completions can go into .bash_profile and be run once on MacOS
# On Ubuntu they have to be run over and over in .bashrc
log_verbose attempt update install
if vergte "$(version_extract "$(bash --version)")" 4.0; then
	log_verbose "install v2 for bash $(version_extract "$(bash --version)")"
	package_install bash-completion@2
	CONFIG="$(config_profile_shell_bash)"
	if in_os linux; then
		CONFIG="$(config_profile_interactive_bash)"
	fi

	if ! config_mark "$CONFIG"; then
		config_add "$CONFIG" <<'EOF'
			if type brew &> /dev/null; then
				if [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
					source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
				else
					for COMPLETION in "$HOMEBREW_PREFIX//etc/bash_completion.d/"*; do
						if [[ -r "$COMPLETION" ]]; then
							source "$COMPLETION"
						fi
					done
				fi
			fi
EOF
	fi

else
	package_install bash-completion
	if ! config_mark "$CONFIG"; then
		config_add "$CONFIG" <<'EOF'
			if [ -r "$HOMEBREW_PREFIX/etc/bash_completion ]; then
				source "$HOMEBREW_PREFIX/etc/bash_completion
			fi
EOF
	fi
	# http://davidalger.com/development/bash-completion-on-os-x-with-brew/
	# this is now deprecated as of Aug 2017
	#if brew list bash-completion > /dev/null
	#then
	#    log_verbose install additional completions
	#    brew tap homebrew/completions
	#fi
	log_verbose "install in the non-login shell profile so it completion always runs"

	if ! config_mark "$(config_profile_for_bash)"; then
		# We need to quote this since it is going into the profile
		# shellcheck disable=SC2016
		# config_add "$(config_profile_shell)" <<<'source "$(brew --prefix)/etc/bash_completion"'
		# latest for brew completions
		# https://docs.brew.sh/Shell-Completion
		config_add "$(config_profile_for_bash)" <<'EOF'
		if type brew &>/dev/null; then
			if [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
				# shellcheck disable=SC1090
				source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
			else
				for COMPLETION in "$HOMEBREW_PREFIX/etc/bash_completion.d/"*; do
					# shellcheck disable=SC1090
					[[ -r "$COMPLETION" ]] && source "$COMPLETION"
				done
			fi
		fi
EOF
	fi
fi
