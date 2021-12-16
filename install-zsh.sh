#!/usr/bin/env bash
##
## install Zsh 
## https://phuctm97.com/blog/zsh-antigen-ohmyzsh
## https://www.viget.com/articles/zsh-config-productivity-plugins-for-mac-oss-default-shell/
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password
			    usage: $SCRIPTNAME [ flags ]
				flags: -d debug (not functional use bashdb), -v verbose, -h help"
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
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-util.sh lib-config.sh

brew install zsh
# install these with zinit so we don't have to add source
#zsh-autosuggestion zsh-syntax-highlighting

log_verbose "Add homebrew zsh to /etc/shells"
ZSH_PATH="$(brew --prefix)/bin/zsh"
config_add_shell "$ZSH_PATH"


log_verbose "Adding Oh My Zsh"
# https://osxdaily.com/2021/11/15/how-install-oh-my-zsh-mac/
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# https://travis.media/top-10-oh-my-zsh-plugins-for-productive-developers/
# from @atong suggestions and https://travis.media/top-10-oh-my-zsh-plugins-for-productive-developers/
# git -  ga git add, gca git commit -av, gd - git diff, gfa - git fetch --all --prune
#        gp - git push
# gh - add command completions for gh
# git-lfs - glfsi git lfs install , glfst - git lfs track
#gnu-utils - use gnu without the g prefix
# helm - command completions
# kubectl - completions and k kubectl, kaf kubectl apply -f
# gcloud - google cloud completions
# pip - command completion
# pipenv - completions, psh pipenv shell, pi - pipenv install
# rg - completions
# asdf - completions
# macos - ofd - open in finder, pfd - print finder path, cdf - change to finder
#       - tab open current directory in a new term tab, music - start Muisc,
#       - pushdf - push finder dir, showfiles - sho hidden in Finder
# 		- btrestart - restart bluetooth
# web-search - type "google any-string"
# copydir - copydir will copy the last path onto clipboard
# copyfile - copy the file to your clipboard
# thefuck - ESC twice to correct command (conflicts with sudo plugin)
# vi-mode - ESC to enter vi edit mode. Another ESC puts in you in normal mode
# one of these is useful probably z
# dirhistory - ALT-Left goes to previous directory, ALT-right so like dirs (does not work with AnnePro2)
# wd - warp directory do a wd add to add to a list of directories
# z - z <string> guess which directory you want to go to 
# colorize - uses pygmenter to ccat files in color
log_verbose "Adding OMZ plugins"
brew install thefuck pygments
PLUGIN+=(
			git macos web-search copydir copyfile dirhistory gh gcloud git-lfs
			gnu-utils asdf colorize
			helm kubectl pip pipenv ripgrep thefuck vi-mode z wd
		) 
config_replace "$ZSH_PROFILE" plugins "plugins = ${PLUGIN[*]}"

log_verbose "adding zinit plugins"
# https://gist.github.com/laggardkernel/4a4c4986ccdcaf47b91e8227f9868ded
brew install zinit
# powerlevel10k - status bar
# zsh-autosuggestions - long suggestions
ZSH_PROFILE="${ZSH_PROFILE:-"$HOME/.zshrc"}"
if ! config_mark "$ZSH_PROFILE"; then
	config_add "$ZSH_PROFILE" <<-EOF
		source "$(brew --prefix)/opt/zinit/zinit.zsh"
		zinit ice wait
		zinit light zsh-users/zsh-autosuggestions
		zinit light romkatv/powerlevel10k
	EOF
fi
