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
export FLAGS="${FLAGS:-""}"

# note INSTALL_CHEZMOI has lots of globals that start like this, so we do not use those
# but INSTALL_CHEZMOI_MOI
INIT_NEW_REPO="${INIT_NEW_REPO:-false}"
REPO_PREFIX="${REPO_PREFIX:-richtong/dotfiles}"
REPO_OS_SUFFIX="${REPO_OS_SUFFIX:-}"
REPO_DEST="${REPO_DEST:-$HOME}"

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

			          -r Repository to use for chezmoi (default: $REPO_PREFIX)
					  -g Where the dotfiles should go (default: $REPO_DEST)
			          -i Initialize a new repo and add dotfiles to it (default: $INIT_NEW_REPO)

			          Note this only works for the same architecture, unlike rich's dotfiles
			          so you will need a dotfile repo for at least MacOS and Linux and
			          probably Ubuntu and Debian. The install attempts to guess the operating system
					  if not set, so the defaults are a suffix or you can hard set with -o where
					  it knwos about Intel or Apple Silicon or uses the Linux name

						  $REPO_PREFIX             MacOS Apple Silicon
						  $REPO_PREFIX-mac-intel   MacOS Intel
			              $REPO_PREFIX-ubuntu    Linux Ubuntu
			              $REPO_PREFIX-debian    Linux Debian
						  $REPO_PREFIX-wsl-ubuntu  Windows Subsystem Ubuntu

			          To start you do a chezmoi init with $SCRIPTNAME -i which adds a default set of files

			          So you can add for files that are not just dotfiles, will work
					    chezmoi add ~/.zshrc
						chezmoi add ~/Library/Application Support/iTerm2/DynamicProfiles/iterm2.profiles.json
						chezmoi add ~/.config/nvim/init.lua

					  This creates local edits to the local repo the workflow as you modify is:
					    chezmoi re-add: your current dotfiles -> local repo
						chezmoi apply: local repo ->  local dotfiles
					    chezmoi cd && git commit -a && git push: local repo -> remote repo

					If you are not installing then it assumes the repo exists and does a:
					    chezmoi init git@github.com:$REPO_PREFIX$REPO_OS_SUFFIX
						chezmoi diff
					Then if you like the changes, you should manually do a
						chezmoi add for those files where  you want to update the repo
						chezmoi cd && git commit && git push to update the repo
						chezmoi apply to apply the dotfiles


					Other file backups will work with chezmoi:

					.nvim is a repo default is richtong/nvim (deprecated)

					dotfiles-stow.sh: Incompatible systems because chezmoi will overwrite the links with real files
					dotfiles-stow.sh links these key things to richtong/dotfile. The -i code detects symlinks, copies the
					real file data and recreates the  symlink, so you can -i to get the initial repo. To get rid of the
					stow, you can run chezmoi apply

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
		REPO_PREFIX="$OPTARG"
		;;
	o)
		REPO_OS_SUFFIX="$OPTARG"
		;;
	i)
		INIT_NEW_REPO="$($INIT_NEW_REPO && echo false || echo true)"
		;;
	g)
		REPO_DEST="$OPTARG"
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
	.warprc
	.zprofile
	.zshrc

	# these are mac specific
	.ssh/config
	Library/Application\ Support/iTerm2/DynamicProfiles/iterm2.profiles.json
	Library/Application\ Support/Code/User/settings.json
	Library/Preferences/com.knollsoft.Rectangle.plist

	# Vim standalone (deprecate)
	.vim.README.rc
	.vim/coc-settings.json
	.vimrc

	# Neovim with LazyVim a pain since you can't do directories
	.config/nvim/init.lua
	.config/nvim/stylua.toml
	.config/nvim/lua/config/README.md
	.config/nvim/lua/config/autocmds.lua
	.config/nvim/lua/config/keymaps.lua
	.config/nvim/lua/config/lazy.lua
	.config/nvim/lua/config/options.lua
	.config/nvim/lua/plugins/base.lua
	.config/nvim/lua/plugins/codecompanion.lua
	.config/nvim/lua/plugins/supertab.lua

)

log_verbose "REPO_OS_SUFFIX:$REPO_OS_SUFFIX"
if [[ -z $REPO_OS_SUFFIX ]]; then
	log_verbose "Automatically setting REPO_OS_SUFFIX based on $(util_os)"
	case $(util_os) in
	mac)
		if [[ ! $(uname -m) =~ arm ]]; then
			REPO_OS_SUFFIX=mac-intel
		fi
		;;
	linux)
		$
		if in_wsl; then
			REPO_OS_SUFFIX=wsl-
		fi
		REPO_OS_SUFFIX+="$(linux_distribution)"
		;;
	esac
fi
log_verbose "REPO_OS_SUFFIX:$REPO_OS_SUFFIX"

log_verbose "Init:$INIT_NEW_REPO"
if $INIT_NEW_REPO; then
	log_verbose "Initializing a new Chezmoi repo"
	chezmoi init
	for FILE in "${INSTALL_CHEZMOI_FILE[@]}"; do
		FULL_FILE="$REPO_DEST/$FILE"
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
	log_verbose "examine the chezmoi and you should now commit this as $REPO_PREFIX"
	log_verbose "you should manually do"
	log_verbose "gh repo create $REPO_PREFIX$REPO_OS_SUFFIX --private --source"
	log_verbose "chezmoi cd && git add . && git commit -m 'initial commit'"
	log_verbose "git remote add origin git@github.com:$REPO_PREFIX"
	log_verbose "git branch -M main && git push -u origin main"
	log_verbose "if an entry is wrong then chezmoi -e _file_"
	log_exit "run again when this is satisfactory"
else
	log_verbose "chezmoi init from $REPO_PREFIX$REPO_OS_SUFFIX"
	chezmoi init "git@github.com:$REPO_PREFIX$REPO_OS_SUFFIX"
	log_warning "Now manually inspect wth chezmoz cd chezmoi diff and then chezmoi apply"
fi

log_verbose "can also install per directory with asdf plugin add chezmoi"

log_verbose "compare with current installation then apply"
# this command shows the diff and then hangs
# chezmoi diff
log_verbose "if ok then manually apply with chezmoi apply -vim"
log_verbose "if you want to change it then chezmoi edit FILE"
log_verbose "you can pull with chezmoi update"
log_verbose "or just chezmoi cd and then use git as usual"
