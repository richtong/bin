#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## install  chezmoi dotfile management
## @author Rich Tong
## @returns 0 on success
#
# https://chezmoi.io/
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
INSTALL_CHEZMOI_REPO="${INSTALL_CHEZMOI_REPO:-richtong/dotfiles}"
# note INSTALL_CHEZMOI_ has lots of globals that start like this, so we do not use those
# but INSTALL_CHEZMOI_MOI
INSTALL_CHEZMOI_OS="${INSTALL_CHEZMOI_OS:-}"
INSTALL_CHEZMOI_INIT="${INSTALL_CHEZMOI_INIT:-false}"
INSTALL_CHEZMOI_DEST="${INSTALL_CHEZMOI_DEST:-$HOME}"
export FLAGS="${FLAGS:-""}"

OPTIND=1
while getopts "hdvfo:ir:g:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password
			usage: $SCRIPTNAME [ flags ]
			flags:
			          -h help
			          -d $($DEBUGGING && echo "no ")debugging
			          -v $($VERBOSE && echo "not ")verbose
			          -f $($FORCE && echo "do not ")force install even $SCRIPTNAME exists

			          -r Repository to use for chezmoi (default: $INSTALL_CHEZMOI_REPO)
			          -i Initialize a new repo (default: $INSTALL_CHEZMOI_INIT)
					  -g Where the files should go (default: $INSTALL_CHEZMOI_DEST)

			          Note this only works for the same architecture, unlike rich's dotfiles
			          so you will need a dotfile repo for at least MacOS and Linux and
			          probably Ubuntu and Debian. The install attempts to guess the operating system
					  if not set, so the defaults are a suffix or you can hard set with -o where
					  it knwos about Intel or Apple Silicon or uses the Linux name

						  $INSTALL_CHEZMOI_REPO             MacOS Apple Silicon
						  $INSTALL_CHEZMOI_REPO-mac-intel   MacOS Intel
			              $INSTALL_CHEZMOI_REPO-ubuntu    Linux Ubuntu
			              $INSTALL_CHEZMOI_REPO-debian    Linux Debian
						  $INSTALL_CHEZMOI_REPO-wsl-ubuntu  Windows Subsystem Ubuntu

			          To start you do a chezmoi init
			          Then for each file you want a chezmoi add ~/.bashrc
			          So you can add for files that are not just dotfiles, will work
						chezmoi add ~/Library/Application Support/iTerm2/DynamicProfiles/iterm2.profiles.json
						chezmoi add ~/.config/nvim/init.lua

					Other file backups will work with chezmoi:

					.nvim is a repo default is richtong/nvim (about to deprecate)
					dotfiles-stow.sh links these key things to richtong/dotfile (deprecated)

		EOF
		exit 0
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
	f)
		FORCE="$($FORCE && echo false || echo true)"
		export FORCE
		;;
	r)
		INSTALL_CHEZMOI_REPO="$OPTARG"
		;;
	o)
		INSTALL_CHEZMOI_OS="$OPTARG"
		;;
	i)
		INSTALL_CHEZMOI_INIT="$($INSTALL_CHEZMOI_INIT && echo false || echo true)"
		;;
	g)
		INSTALL_CHEZMOI_DEST="$OPTARG"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

if in_os mac; then

	log_verbose "Mac install"
fi

PACKAGE+=(
	chezmoi
)

log_verbose "Install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

#
INSTALL_CHEZMOI_FILE+=(

	.aws/config
	.config/direnv/direnvrc
	.config/lvim/config.lua
	.config/powerline/colors.json
	.config/powerline/config.json
	.config/thefuck/settings.py
	.config/tmuxinator/restart.yml
	.config/yamllint/config
	.jupyter/jupyter_notebook_config.py
	.jupyter/lab/user-settings/@jupyterlab/tracker.jupyterlab-settings
	.jupyter/nbconfig.json
	.jupyter/nbconfig/notebook.json
	.bash_profile
	.bashrc
	.condarc
	.default-python-packages
	.dir_colors
	.dircolors
	.envrc
	.eslintrc.js
	.fzf_bash
	.fzf_zsh
	.gitconfig
	.octaver1Gc
	.p10k.zsh
	.profile
	.stylelintc
	.tmux.conf
	.tool-versions
	.vim.README.rc
	.vim/coc-settings.json
	.vimrc
	.warprc
	.zprofile
	.zshrc

	# these are mac specific
	.ssh/config
	Library/Application\ Support/iTerm2/DynamicProfiles/iterm2.profiles.json
	Library/Application\ Support/Code/User/settings.json
	Library/Preferences/com.knollsoft.Rectangle.plist

)

log_verbose "INSTALL_CHEZMOI_OS:$INSTALL_CHEZMOI_OS"
if [[ -z $INSTALL_CHEZMOI_OS ]]; then
	log_verbose "Automatically setting INSTALL_CHEZMOI_OS based on $(util_os)"
	case $(util_os) in
	mac)
		if [[ ! $(uname -m) =~ arm ]]; then
			INSTALL_CHEZMOI_OS=mac-intel
		fi
		;;
	linux)
		$
		if in_wsl; then
			INSTALL_CHEZMOI_OS=wsl-
		fi
		INSTALL_CHEZMOI_OS+="$(linux_distribution)"
		;;
	esac
fi
log_verbose "INSTALL_CHEZMOI_OS:$INSTALL_CHEZMOI_OS"

log_verbose "Init:$INSTALL_CHEZMOI_INIT"
if $INSTALL_CHEZMOI_INIT; then
	log_verbose "Initializing a new Chezmoi repo"
	chezmoi init
	for FILE in "${INSTALL_CHEZMOI_FILE[@]}"; do
		FULL_FILE="$INSTALL_CHEZMOI_DEST/$FILE"
		if [[ -e $FULL_FILE ]]; then
			if [[ -L $FULL_FILE ]]; then
				log_verbose "$FULL_FILE is a symlink, so get the contents and check in"
				mv $"$FULL_FILE" $"$FULL_FILE".ln
				cp $"$FULL_FILE".ln $"$FULL_FILE"
				chezmoi add $"$FULL_FILE"
				mv $"$FULL_FILE".ln $"$FULL_FILE"
			else
				log_verbose "adding $FULL_FILE"
				chezmoi add "$FULL_FILE"
			fi
		fi
	done
	log_verbose "examine the chezmoi and you should now commit this as $INSTALL_CHEZMOI_REPO"
	log_verbose "you should manually do"
	log_verbose "gh repo create $INSTALL_CHEZMOI_REPO$INSTALL_CHEZMOI_OS --private --source"
	log_verbose "chezmoi cd && git add . && git commit -m 'initial commit'"
	log_verbose "git remote add origin git@github.com:$INSTALL_CHEZMOI_REPO"
	log_verbose "git branch -M main && git push -u origin main"
	log_verbose "if an entry is wrong then chezmoi -e _file_"
	log_exit "run again when this is satisfactory"
else
	log_verbose "Assumes $INSTALL_CHEZMOI_REPO$INSTALL_CHEZMOI_OS exists"
	chezmoi init "git@github.com:$INSTALL_CHEZMOI_REPO$INSTALL_CHEZMOI_OS"
fi

log_verbose "can also install per directory with asdf plugin add chezmoi"

log_verbose "compare with current installation then apply"
# this command shows the diff and then hangs
# chezmoi diff
log_verbose "if ok then manually apply with chezmoi apply -vim"
log_verbose "if you want to change it then chezmoi edit FILE"
log_verbose "you can pull with chezmoi update"
log_verbose "or just chezmoi cd and then use git as usual"
