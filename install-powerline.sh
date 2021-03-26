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
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvp" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Powerline
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
					   -f install powerline not powerline-go and vim-airline
					   (default: $INSTALL_POWERLINE)
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
		INSTALL_POWERLINE=true
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

brew_install powerline-go svn

log_verbose "installing powerline fonts"
cask_install font-fira-mono-for-powerline

if ! $INSTALL_POWERLINE; then
	log_verbose "Installing Powerline-Go"
	# https://github.com/vim-airline/vim-airline
	# recommend .profile but .bashrc works better
	# for pipenv shell etc
	if ! config_mark "$(config_profile_shell)"; then
		config_add "$(config_profile_shell)" <<'EOF'
function _update_ps1() {
    # shellcheck disable=SC2046
    PS1=$(powerline-go -hostname-only-if-ssh -max-width 30
		  -colorize-hostname -shorten-gke-names -theme solarized-dark16
		  -modules venv,user,host,ssh,cwd,perms,git,hg,jobs,exit,root,docker,docker-content,goenv,kube
		  -error $? -jobs "$(jobs -p | wc -l)")
}
if [[ $TERM != linux ]] && command -v powerline-go >& /dev/null; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
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
if [[ ! -e $PROFILE/config.json ]]; then
	log_verbose "copying from $config to $PROFILE"
	cp -r "$config/"* "$PROFILE"
fi

if ! config_mark "$(config_profile_shell)"; then
	config_add "$(config_profile_shell)" <<EOF
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
