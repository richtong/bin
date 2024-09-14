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

LAZYVIM="{LAZYVIM:-true}"
# change this to your own fork if you want to keep updates going
# of create your own tracking branch
LAZYVIM_REPO="{LAZYVIM_REPO:-https://github.com/LazyVim/starter}"
LUNARVIM="{LUNARVIM:-true}"
NVIM_CONFIG="${NVIM_CONFIG:-"$HOME/.config/nvim"}"

OPTIND=1
while getopts "hdvfalu" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Install neovim with all the plugins
			      Install lazyvim and lunarvim as alternative

			flags:
			      -h help
			  -d $($DEBUGGING || echo "no ")debugging
			  -v $($VERBOSE || echo "not ")verbose
			  -f $($FORCE || echo "no ")force install
			  -a $($ALIAS || echo "no ")set alias as vi
			      -l $($LAZYVIM || echo "no ")lazyvim install
			      -u $($LUNARVIM || echo "no ")lunarvim install

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
	l)
		LAZYVIM="$($LAZYVIM && echo false || echo true)"
		;;
	u)
		LUNARVIM="$($LUNARVIM && echo false || echo true)"
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

PACKAGE+=(
	neovim
	# used by LazyVim
	fd       # better find used by LazyVim
	luarocks # lua package manager
	git
	rg      # ripgrep searching
	lazygit # git in nvim
	# for none-ls which pretends it is null-ls in :checkhealth
	# it let's non-LSP tools brdge in LSP to use telescope and trouble
	prettier          # code formatter
	black             # python code formatter
	hadolint          # Dockerfile linter
	markdownlint-cli2 # latest markdown linter
	stylua            # lua formatter
	shfmt             # bash formatter
	# vimtex for Latex in LazyVim
	biber
)

package_install "${PACKAGE[@]}"

log_verbose "install node and python helpers"

log_warning "If you are using asdf or conda or pipenv then pip install neovim
all environments"
log_warning "if you get python3 not found error in neovim the pip install
neovim"
# pynvim for deoplete is a dependency of neovim so just need one installations
PIP_PACKAGE+=(
	neovim
	ruff-lsp   # python format, linting
	pylatexenc # for lazyvim extras render-markdown to render Latex string
)
pip_install "${PIP_PACKAGE[@]}"

# needed for not integration
log_verbose "if you are using asdf then you need to npm install neovim locally"
NODE_PACKAGE+=(
	neovim
)
# global installation is needed for neovim
node_install -g "${NODE_PACKAGE[@]}"

log_verbose "if using asdf then you need ruby locally"
RUBY_PACKAGE+=(
	neovim
)
gem_install "${RUBY_PACKAGE[@]}"

log_verbose "if you are using Latex, then install the biblml"
if command -v latex >/dev/null; then
	sudo tlmgr install latexmk
fi

log_verbose "install IDE tools done by install.sh"
"$SCRIPT_DIR/install-lint.sh"

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

# lunarvim runs as lvim and is a separate configuration
if $LUNARVIM; then
	log_verbose "Install LunarVim, the full IDE variant as lvim"
	LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh)
fi

if [[ -e $NVIM_CONFIG ]] && ! $FORCE; then
	log_exit "$NVIM_CONFIG exists use -f to overwrite"
fi

# https://wiki.archlinux.org/index.php/Neovim
# you cannot use a tilde here readlink does not like it in lib-config
log_verbose "creating $NVIM_CONFIG"
mkdir -p "$NVIM_CONFIG"

if $LAZYVIM; then
	log_verbose "Install lazyvim as a repo in $NVIM_CONFIG"
	git clone "$LAZYVIM_REPO" "$NVIM_CONFIG"
	log_verbose "Remove $NVIM_CONFIG/.git if you do not want updates from $LAZYVIM_REPO"
else
	# https://www.linode.com/docs/tools-reference/tools/how-to-install-neovim-and-plugins-with-vim-plug/
	# https://www.reddit.com/r/neovim/comments/3z6c2i/how_does_one_install_vimplug_for_neovim/
	# we actually just source .vimrc and expect install-vim.sh to be nvim
	# compatible
	NVIM_INIT="${NVIM_INIT:-"$NVIM_CONFIG/init.vim"}"
	log_verbose "creating $NVIM_INIT to point to .vimrc"
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
fi
