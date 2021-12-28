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
# asdf - completions (not working)
# macos - ofd - open in finder, pfd - print finder path, cdf - change to finder
#       - tab open current directory in a new term tab, music - start Muisc,
#       - pushdf - push finder dir, showfiles - sho hidden in Finder
# 		- btrestart - restart bluetooth
# web-search - type "google any-string"
# copydir - copydir will copy the last path onto clipboard
# copyfile - copy the file to your clipboard
# thefuck - ESC twice to correct command (conflicts with sudo plugin)
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vi-mode
# vi-mode - ESC to enter vi edit mode. Another ESC puts in you in normal mode
#           While in command mode, typing vv quickly will bring you to the full
#           vi with the command in a window.
# one of these is useful probably z
# dirhistory - ALT-Left goes to previous directory, ALT-right so like dirs (does not work with AnnePro2)
# wd - warp directory do a wd add to add to a list of directories
# z - z <string> guess which directory you want to go to
# colorize - uses pygmenter to ccat files in color
# fzf - completions
# brew - new command bubo brew update & brew outdated bubc brew update && brew
# cleanup
# command-not-found - suggest missing package
# command aliases - l ls -lFh h history ff find . -type f -name hgrep
# docker completions
# emoji-clock - emoji not characters for clock
# gcloud - completions
# git-lfs - completions
log_verbose "Adding OMZ plugins"
brew install pygments
log_verbose "Install fzf after vi-mode as the Ctrl-R conflict"

PLUGIN+=(

	aws
	brew
	colorize
	command-not-found
	common-aliases
	copydir
	copyfile
	dirhistory
	docker
	dotenv
	emoji-clock
	vi-mode
	fzf
	gcloud
	gh
	git
	git-lfs
	gnu-utils
	helm
	history
	ipfs
	kubectl
	macos
	microk8s
	npm
	npx
	pip
	pipenv
	rand-quote
	ripgrep
	terraform
	thefuck
	themes
	transfer
	wd
	web-search
	z
	zsh-interactive-cd

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
		zinit light joel-porquet/zsh-dircolors-solarized.git
		setupsolarized
	EOF
fi
