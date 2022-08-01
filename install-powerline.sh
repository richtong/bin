#!/usr/bin/env bash
##
## install Powerline for neat looking status lines
## https://medium.com/@earlybyte/powerline-for-bash-6d3dd004f6fc
##
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
INSTALL_POWERLINE=${INSTALL_POWERLINE:-false}
VIM_PROFILE="${VIM_PROFILE:-"$HOME/.vimrc"}"
WINDOWS_ADMIN="${WINDOWS_ADMIN:-"service-account"}"
FORCE="${FORCE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvlw:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Powerline
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help
					   -l install powerline not powerline-go and vim-airline (default: $INSTALL_POWERLINE)
					   -w Windows administrator account if in WSL not used (default:$WINDOWS_ADMIN)
					   -f Install Powerline font for Windows (default: $FORCE)
					      Set to false because you get a zillion confirms
						  otherwise so only do -f once
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
	l)
		INSTALL_POWERLINE=true
		;;
	w)
		WINDOWS_ADMIN="$OPTARG"
		;;
	*)
		echo "not flag -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh lib-config.sh

log_verbose "install powerline-go and powerline-status packages"
pip_install powerline-status powerline-gitstatus

package_install powerline-go svn

if in_os mac; then
	FONT=(
		font-fira-mono-for-powerline
		font-sf-mono-for-powerline
		font-menlo-for-powerline
	)

	tap_install homebrew/cask-fonts
	# brew as of June 2022 does not handle reinstall correctly.
	# throws an error. So uninstall it and reinstall do not just delete
	# as it will show as installed.
	log_verbose "uninstalling powerline ${FONT[*]}"
	package_uninstall "${FONT[@]}"
	#log_verbose "Manually delete the fonts so install can happen"
	#rm -f "$HOME/Library/Fonts/FuraMono-"* \
	#    "$HOME/Library/Fonts/SF-Mono-Powerline-"* \
	#    "$HOME/Library/Fonts/Menlo"*
	log_verbose "installing powerline ${FONT[*]}"
	package_install "${FONT[@]}"

else
	log_verbose "In linux have to install fonts from repo"
	if [[ ! -e $SOURCE_DIR/extern/fonts ]]; then
		log_warning "no powerline-fonts repo cloned $SOURCE_DIR/extern/fonts"
	else
		pushd "$SOURCE_DIR/extern/fonts" &>/dev/null || true
		if in_wsl; then
			# https://stackoverflow.com/questions/16107381/how-to-complete-the-runas-command-in-one-line
			# https://answers.microsoft.com/en-us/windows/forum/windows_10-security/windows-10-run-as-administrator-using-microsoft/f2b75044-ef0d-4acd-86d9-c6c7998664ab
			#log_warning "It does not work To use a Microsoft Account as admin switch to local"
			#log_warning "so create a service-account instead with local password"
			#runas.exe /savecred /user:"$WINDOWS_ADMIN" "./install.ps1"
			# https://www.raymondcamden.com/2017/09/25/calling-a-powershell-script-from-wsl
			log_verbose "will install fonts"
			if $VERBOSE; then
				powershell.exe -File '.\install.ps1' -WhatIf
			fi
			if $FORCE; then
				powershell.exe -File '.\install.ps1'
			fi
			log_warning "change the Terminal font to use a Powerline one and"
			log_warning "restart the terminal session"
		else
			sudo apt-get install fontconfig
			./install.sh
			log_verbose "Installed fonts are:"
			if $VERBOSE; then
				fc-list
			fi
			popd &>/dev/null || true
		fi
	fi
fi

# gcp - unusable do not use 10 seconds at least
# kube - very slow 1-2 seconds
# docker - uses ~/.docker to detect if running in a container not needed much
# venv-name-size-limit does not work
MODULES="${MODULES:-"venv,node,goenv,user,host,ssh,cwd,perms,git,jobs,exit,root"}"
# priorities if the prompt exceeds % max-width of screen
# deprioritieze user we know who we are usually
PRIORITIES="${PRIORITIES:-"root,cwd,venv,host,ssh,perms,git-branch,git-status,hg,user,jobs,exit,cwd-path"}"

if in_wsl; then
	log_verbose "In WSL git is very expensive in Windows file systems so do not use"
	MODULES="venv,user,host,ssh,cwd,perms,hg,jobs,exit,root,docker,goenv,kube"
fi

# status line meanings
# ✎ -- a file has been modified, but not staged for commit
# ✔ -- a file is staged for commit
# ✼ -- a file has conflicts
# + -- untracked files are present
# ⚑ -- stash is present
if ! $INSTALL_POWERLINE; then
	log_verbose "Installing Powerline-Go"
	# https://github.com/vim-airline/vim-airline
	# recommend .profile but .bashrc works better
	# for pipenv shell etc
	# note max-width seems buggy will sometimes just truncate
	#-max-width 30 \
	if ! config_mark "$(config_profile_nonexportable)"; then
		config_add "$(config_profile_nonexportable)" <<-EOF
			function _update_ps1() {
			    # shellcheck disable=SC2046
			    PS1=\$(powerline-go \
						-max-width 50 -cwd-max-dir-size 4 -cwd-max-depth 4 -condensed \
						-theme solarized-dark16 \
						-colorize-hostname -hostname-only-if-ssh \
						-shorten-gke-names -shorten-eks-names \\
						-modules \
							"$MODULES" \
						-priority \
							"$PRIORITIES" \
						-error \$? -jobs "\$(jobs -p | wc -l)")
			}
			if [[ $TERM != linux ]] && command -v powerline-go >& /dev/null; then
			    PROMPT_COMMAND="_update_ps1; \$PROMPT_COMMAND"
			fi
		EOF
	fi
	# https://github.com/vim-airline/vim-airline
	log_verbose "Installing vim-airline this needs to go in PlugBegin"
	if ! config_mark "$VIM_PROFILE" \"; then
		config_add "$VIM_PROFILE" <<-EOF
			" Add in Plug Begin
			" Plug 'vim-airline/vim-airline'
			" Plug 'vim-airline/vim-airline-themes'
			let g:airline#extensions#tabline#enabled = 1
		EOF
	fi
	log_exit "success installing vim-airline and powerline-go"
fi

log_warning "powerline-status doe not work with python 3.9"
log_verbose "Installing Powerline and Vim addon"

log_verbose "installing powerline control scripts"
location="$(pip show powerline-status | grep Location | awk '{print $2}')"/powerline
log_verbose "powerline completion script at $location"

powerline="$location/bindings/bash/powerline.sh"
if [[ ! -e $powerline ]]; then
	log_error 2 "cannot find powerline at $powerline"
fi

config="$location/config_files"
PROFILE="${PROFILE:-"$HOME/.config/powerline"}"
mkdir -p "$PROFILE"
if [[ ! -e $PROFILE/config.json ]]; then
	log_verbose "copying from $config to $PROFILE"
	cp -r "$config/"* "$PROFILE"
fi

if ! config_mark "$(config_profile_nonexportable)"; then
	config_add "$(config_profile_nonexportable)" <<-EOF
		if [[ -r $powerline ]]; then
			powerline-daemon -q
			export POWERLINE_BASH_CONTINUATION=1
			export POWERLINE_BASH_SELECT=1
			source "$powerline" || true
		fi
	EOF
fi

if ! config_mark "$VIM_PROFILE" \"; then
	log_verbose "adding to $VIM_PROFILE"
	config_add "$VIM_PROFILE" '"' <<-EOF
		set rtp+="$location/bindings/vim"
		set laststatus=2
	EOF
fi
# https://github.com/gravyboat/powerline-config

log_verbose "change config at $PROFILE"
log_verbose "run powerline-lint to check and then powerline-daemon --replace"
log_verbose "on python version changes, need to delete the files and reset"
log_verbose "Set iterm/Preferences/Profiles/Font to Fira Mono"
log_verbose "Set iterm/Preferenes/Profiles/Colors to Solarized Dark"
log_verbose "source $(config_profile_shell) or re-login to use"
