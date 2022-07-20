#!/usr/bin/env bash
#
# neovim inpsired by python specific fixes
# https://www.vimfromscratch.com/articles/vim-for-python/
# https://hanspinckaers.com/posts/2020/01/vim-python-ide/
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
export SCRIPTNAME
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# Pass the force flag down
FORCE="${FORCE:-false}"
FLAGS="${FLAGS:-""}"
ALIAS="${ALIAS:-false}"
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
while getopts "hdvfa" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Install newvim with all the plugins

			flags:  -h help
				    -d $($DEBUGGING || echo "no ")debugging
				    -v $($VERBOSE || echo "not ")verbose
					-f $($FORCE || echo "no ")force install
				    -a $($ALIAS || echo "no ")set alias as vi
		EOF
		exit 0
		;;
	d)
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
		FLAGS+=" -f "
		;;
	a)
		ALIAS="$($ALIAS && echo false || echo true)"
		;;
	*)
		echo "no flag $opt"
		;;
	esac
done
# https://github.com/hadolint/hadolint/issues/343
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh

brew_install neovim

log_verbose "get neovim python packages in system python"
log_warning "All pipenv installation need this in the python world"
# pynvim for deoplete
pip_install neovim pynvim

log_verbose "install IDE tools done by install.sh"
#"$SCRIPT_DIR/install-lint.sh"

log_verbose "create vi as alias for nvim and set git to use it"
if $ALIAS; then
	# use a null string because this will get the default shell
    # put into .zshrc even though it could go into .zprofile
    # since these are just paths
	for PROFILE in "" "$(config_profile_nonexportable_zsh)"; do
		log_verbose "Adding config to ${PROFIlE:-default}"
		# shellcheck disable=SC2086
		if ! config_mark $PROFILE; then
			# shellcheck disable=SC2086
			config_add $PROFILE <<-'EOF'
				if command -v nvim >/dev/null; then
					VISUAL="$(command -v nvim)"
					export VISUAL
					export EDITOR="$VISUAL"
				fi
			EOF
		fi
	done
	# note that zsh only has .zshrc but bash has .bash_profile and .bashrc
	# alias should go into the .bashrc for interactive shell
	for SHELL_PROFILE in "$(config_profile_nonexportable)" "$(config_profile_zsh)"; do
		log_verbose "Add alias to the interactive shell to $SHELL_PROFILE"
		if ! config_mark "$SHELL_PROFILE"; then
			config_add "$SHELL_PROFILE" <<-EOF
				if command -v nvim >/dev/null; then alias vi=nvim; fi
			EOF
		fi
	done
fi
git config --global core.editor "nvim"

# https://wiki.archlinux.org/index.php/Neovim
# you cannot use a tilde here readlink does not like it in lib-config
NVIM_CONFIG="${NVIM_CONFIG:-"$HOME/.config/nvim"}"
log_verbose "creating $NVIM_CONFIG"
mkdir -p "$NVIM_CONFIG"

# https://www.linode.com/docs/tools-reference/tools/how-to-install-neovim-and-plugins-with-vim-plug/
# https://www.reddit.com/r/neovim/comments/3z6c2i/how_does_one_install_vimplug_for_neovim/
# we actually just source .vimrc and expect install-vim.sh to be nvim
# compatible
NVIM_INIT="${NVIM_INIT:-"$NVIM_CONFIG/init.vim"}"
log_verbose "creating $NVIM_INIT"
if ! config_mark "$NVIM_INIT" '"'; then
	log_verbose "creating $NVIM_INIT"
	config_add "$NVIM_INIT" <<-'EOF'
		" check for vim-plug install if needed
		" https://github.com/junegunn/vim-plug/issues/739
		let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'

		        set runtimepath^=~/.vim runtimepath+=~/.vim/after
		        let &packpath = &runtimepath
		        source ~/.vimrc

	EOF
fi
