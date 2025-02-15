#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Install asdf and dotenv for language and tool management
## Like pipenv for the system
## http://asdf-vm.com
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
VERSION="${VERSION:-7}"
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DIRENV_CONFIG="${DIRENV_CONFIG:=$XDG_CONFIG_HOME/direnv}"
DIRENVRC="${DIRENVRC:=$DIRENV_CONFIG/direnvrc}"

# make the default an array needs a hack
# https://stackoverflow.com/questions/27554957/how-to-set-the-default-value-of-a-variable-as-an-array
# https://unix.stackexchange.com/questions/10898/write-default-array-to-variable-in-bash
# These versions should be kept in sync with .tool_versions in ./src, ./bin, ./lib and ./user/rich
# Assumes the last item is the one to be set for global
DEFAULT_NODE=(20.18.1 22.11.0)
if ((${#DEFAULT_NODE[@]} > 0)); then NODE_VERSION=("${NODE_VERSION[@]:-${DEFAULT_NODE[@]}}"); fi

DEFAULT_DIRENV=(2.35.0)
if ((${#DEFAULT_DIRENV[@]} > 0)); then DIRENV_VERSION=("${DIRENV_VERSION[@]:-${DEFAULT_DIRENV[@]}}"); fi

# Python 3.11.8 has to be built so use a lower version as of Mar 2024
DEFAULT_PYTHON=(3.11.10 3.12.7)
if ((${#DEFAULT_PYTHON[@]} > 0)); then PYTHON_VERSION=("${PYTHON_VERSION[@]:-${DEFAULT_PYTHON[@]}}"); fi

# openjdk18 is Java 8 for Unifi.app no longer needed, 23 for tika
DEFAULT_JAVA=(openjdk-23)
if ((${#DEFAULT_JAVA[@]} > 0)); then JAVA_VERSION=("${JAVA_VERSION[@]:-${DEFAULT_JAVA[@]}}"); fi

# Ruby is used with LazyVim
DEFAULT_RUBY=(3.3.4)
if ((${#DEFAULT_RUBY[@]} > 0)); then RUBY_VERSION=("${RUBY_VERSION[@]:-${DEFAULT_RUBY[@]}}"); fi

# UV is used with LazyVim
DEFAULT_UV=(0.4.17)
if ((${#DEFAULT_UV[@]} > 0)); then UV_VERSION=("${UV_VERSION[@]:-${DEFAULT_UV[@]}}"); fi

# Go used in Hugo
DEFAULT_GOLANG=(1.23.2)
if ((${#DEFAULT_GOLANG[@]} > 0)); then GOLANG_VERSION=("${GOLANG_VERSION[@]:-${DEFAULT_GOLANG[@]}}"); fi

# Go used in Vite
DEFAULT_RUST=(1.83.0)
if ((${#DEFAULT_RUST[@]} > 0)); then RUST_VERSION=("${RUST_VERSION[@]:-${DEFAULT_RUST[@]}}"); fi

# pip packages as installed executables
DEFAULT_PIPX=(1.7.1)
if ((${#DEFAULT_PIPX[@]} > 0)); then PIPX_VERSION=("${PIPX_VERSION[@]:-${DEFAULT_PIPX[@]}}"); fi

export FLAGS="${FLAGS:-""}"
while getopts "hdvn:e:p:j:r:u:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs asdf multiple runtime version management
			usage: $SCRIPTNAME [ flags ]
				flags: -h help
				-d $($DEBUGGING || echo "no ")debugging
				-v $($VERBOSE || echo "not ")verbose
				You can use a quote string to install more than one version
				So -p "3.10.1 3.11.4" works
				-p Python version (default: ${PYTHON_VERSION[*]})
				-e Direnv version (default: ${DIRENV_VERSION[*]})
				-n Node.js version (default: ${NODE_VERSION[*]})
				-j Java version (default: ${JAVA_VERSION[*]})
				-r Ruby version (default: ${RUBY_VERSION[*]})
				-u UV version (default: ${UV_VERSION[*]})
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
	p)
		# https://ioflood.com/blog/bash-split-string-into-array/
		# https://unix.stackexchange.com/questions/763312/how-to-ignore-control-characters-when-execute-read-in-bash
		read -ra PYTHON_VERSION <<<"$OPTARG"
		;;
	e)
		read -ra DIRENV_VERSION <<<"$OPTARG"
		;;
	n)
		read -ra NODE_VERSION <<<"$OPTARG"
		;;
	j)
		read -ra JAVA_VERSION <<<"$OPTARG"
		;;
	r)
		read -ra RUBY_VERSION <<<"$OPTARG"
		;;
	u)
		read -ra UV_VERSION <<<"$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

log_verbose "Install asdf core"
log_verbose "Install asdf support including gcc if it has to build from source"

PACKAGE+=(
	asdf
	direnv
	gawk
	gcc
	gpg
)
package_install "${PACKAGE[@]}"

#  this linking does not work to fix asdf install python issues
# https://github.com/pyenv/pyenv/issues/950
# but retaining the code in case it's needed
# if [[ ! -e $HOMEBREW_PREFIX/bin/gcc ]]; then
# 	log_verbose "link gcc keg only"
# 	if ! pushd "$HOMEBREW_PREFIX/bin" >/dev/null; then
# 		log_exit 1 "no $HOMEBREW_PREFIX/bin"
# 	fi
# 	log_verbose "In $HOMEBREW_PREFIX/bin"
# 	GCC_WITH_VERSION="$(brew info gcc | grep -o "gcc/[0-9]*" | tr / -)"
# 	if [[ ! -e $GCC_WITH_VERSION ]]; then
# 		log_exit 2 "no $GCC_WITH_VERSION"
# 	fi
# 	log_verbose "linking $GCC_WITH_VERSION to gcc"
# 	ln -s "$GCC_WITH_VERSION" gcc
# 	popd >/dev/null
# fi

# https://stackoverflow.com/questions/28725333/looping-over-pairs-of-values-in-bash
declare -A ASDF+=(
	[direnv]=${DIRENV_VERSION[@]}
	[java]=${JAVA_VERSION[@]}
	[nodejs]=${NODE_VERSION[@]}
	[ruby]=${RUBY_VERSION[@]}
	[python]=${PYTHON_VERSION[@]}
	[uv]=${UV_VERSION[@]}
	[golang]=${GOLANG_VERSION[@]}
	[pipx]=${PIPX_VERSION[@]}
)

log_verbose "ASDF indexes ${!ASDF[*]} and data ${ASDF[*]}"

# https://github.com/pyenv/pyenv/issues/950
# asdf install python uses pyenv underneath and brew install open-ssl does not put the
# headers in the right place, so set it manually as shell variables
# uses the return of null if there is no key value assigned so only using it for python rn.
# shellcheck disable=SC2016
declare -A ASDF_ENV+=(
	[python]='CFLAGS="-I$(brew --prefix openssl)/include" LDFLAGS="-L$(brew --prefix openssl)/lib"'
)

declare -A ASDF_URL+=(
	[direnv]='https://github.com/richtong/asdf-direnv'
)

log_warning "use oh-my-zsh asdf plugin to install paths"

#  https://stackoverflow.com/questions/19816275/no-acceptable-c-compiler-found-in-path-when-installing-python
if in_os linux; then
	log_verbose "Install Linux prerequisites for asdf python"
	package_install build-essential libssl-dev zlib1g-dev \
		libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
		libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
fi

log_warning "asdf python version installed, you need to make sure that the default is loaded"
log_verbose "pip packages are installed in $HOME with .default-python-packages"
PIP_PACKAGE+=(
	"neovim"
)
if ! config_mark "$HOME/.default-python-packages"; then
	log_verbose "Adding to $HOME/.default-python-packages"
	# https://superuser.com/questions/461981/how-do-i-convert-a-bash-array-variable-to-a-string-delimited-with-newlines
	config_add "$HOME/.default-python-packages" <<-EOF
		$(printf "%s\n" "${PIP_PACKAGE[@]}")
	EOF
fi

# the ! means all keys of an array
# https://unix.stackexchange.com/questions/91943/is-there-a-way-to-list-all-indexes-ids-keys-on-a-bash-associative-array-vari
log_verbose "Installing asdf plugins from ${ASDF[*]}"
for LANG in "${!ASDF[@]}"; do
	log_verbose "looking for $LANG"
	# this command only work if you run it first
	# asdf plugin list
	if ! asdf plugin list | grep "$LANG"; then
		# shellcheck disable=SC2086
		log_verbose run: asdf plugin add "$LANG" ${ASDF_URL["$LANG"]:-}
		# shellcheck disable=SC2086
		if ! asdf plugin add "$LANG" ${ASDF_URL["$LANG"]:-}; then
			log_verbose "asdf plugin add $LANG error $?"
		fi
	else
		log_verbose "asdf plugin $LANG already installed so update it"
		asdf plugin update "$LANG"
		if ! asdf plugin update "$LANG"; then
			log_verbose "asdf plugin update $LANG error $?"
		fi
	fi
	INSTALLED=
	if asdf list "$LANG"; then
		INSTALLED="$(asdf list "$LANG" 2>&1 | sed 's/*//')"
		log_verbose "Is $LANG has versions $INSTALLED installed already"
	fi

	# note you cannot array index you can only enumerate so ${ASDF[$LANG][-1]} does not work
	# note this word splits so versions cannot have spaces there seems to be no
	# way to generate an array here
	for VERSION in ${ASDF[$LANG]}; do
		log_verbose "looking for version $VERSION"
		# remove the asterisk which means current selected
		# shellcheck disable=SC2086

		if [[ ! -v INSTALLED || ! $INSTALLED =~ $VERSION ]]; then
			# broken as of feb 2021 now fixed
			#if in_os mac && ! mac_is_arm && [[ $p =~ python ]]; then
			#    log_verbose "Current bug in asdf python install skipping"
			#    continue
			#fi

			log_verbose try eval ${ASDF_ENV[$LANG]:-} asdf install "$LANG" "$VERSION"

			# python needs an environment set so add it as needed with eval
			# note we use {:-} since not all ASDF_ENVs are set
			# shellcheck disable=SC2086
			eval ${ASDF_ENV[$LANG]:-} asdf install "$LANG" "$VERSION"
			# does the global multiple times because there is no way to do double index
			# so in effect the last version is the global do not set anything
			# log_verbose  asdf set "$LANG" "$VERSION"
			# asdf set "$LANG" "$VERSION"
		fi
	done
done

source_profile
# shellcheck disable=SC2016
# ASDF_DATA_DIR="${ASDF_DATA_DIR:-'$HOME/.asdf'}"
# if ! config_mark; then
# config_add <<-EOF
# ASDF_DATA_DIR="$ASDF_DATA_DIR"
# EOF
# fi

# this is no longer needed run the asdf setup instead
# https://github.com/asdf-community/asdf-direnv
#DIRENVRC="${DIRENVRC:-"$HOME/.config/direnv/direnvrc"}"
#if ! config_mark "$DIRENVRC"; then
#    log_verbose "adding to $DIRENVRC"
#    config_add "$DIRENVRC" <<-'EOF'
#        source "$(asdf direnv hook asdf)"
#        # make direnv silent by default
#        export DIRENV_LOG_FORMAT=""
#    EOF
#fi

ENVRC="${ENVRC:-"$HOME/.envrc"}"
if ! config_mark "$ENVRC"; then
	log_verbose "Adding $ENVRC"
	# allow if direnv exists
	if command -v direnv >/dev/null; then
		direnv allow "$ENVRC"
	fi
	log_verbose "Adding to $ENVRC"
	config_add "$ENVRC" <<-'EOF'
		use asdf
	EOF
fi

if ! config_mark "$HOME/.asdfrc"; then
	log_verbose "Adding to $$HOME/.asdfrc"
	config_add "$HOME/.asdfrc" <<-'EOF'
		java_macos_integration_enable = yes
	EOF
fi

# this is a direnv pro tip but doesn't work so always add the asdf shims
# if [[ -r $HOME/.asdf/bin && ! $PATH =~ .asdf/bin ]]; then PATH="$HOME/.asdf/bin:$PATH"; fi
log_verbose "completions for zsh add plugins+=(asdf) to .zshrc"
for shell_type in bash zsh; do
	if ! config_mark "$(config_profile_nonexportable_$shell_type)"; then
		log_verbose "Adding to $(config_profile_nonexportable_$shell_type)"
		if [[ $shell_type == bash ]]; then
			config_add "$(config_profile_nonexportable_$shell_type)" <<'EOF'
			source <(asdf completion $shell_type)
			eval "$(direnv hook $shell_type)"
fi
EOF
		fi
		log_verbose "adding shell setup for direnv version ${ASDF[direnv]}"
		if [[ -n ${ASDF[direnv]} ]]; then
			log_verbose "Adding asdf-direnv for $shell_type"
			if ! asdf cmd direnv setup --shell "$shell_type" --version "${ASDF[direnv]}"; then
				log_verbose "direnv setup failed"
			fi
		fi
		# https://github.com/halcyon/asdf-java#java_home
		log_verbose "java=${ASDF[java]}"
		if [[ -n ${ASDF[java]} ]]; then
			log_verbose "Adding java_home for $shell_type"
			config_add "$(config_profile_nonexportable_$shell_type)" <<EOF
if command -v asdf >/dev/null && asdf current java &>/dev/null; then
	# shellcheck disable=SC1090,SC1091
	source "\$HOME/.asdf/plugins/java/set-java-home.$shell_type"
fi
EOF
		fi
	fi
done

# shellcheck disable=SC2016
ASDF_DATA_DIR="${ASDF_DATA_DIR:-'$HOME/.asdf'}"
if ! config_mark; then
	config_add <<-'EOF'
		export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
		if [ -r "$ASDF_DATA_DIR/shims" ] && ! echo "$PATH" | grep -q "$ASDF_DATA_DIR/shims"; then PATH="$ASDF_DATA_DIR/shims:$PATH"; fi
	EOF
fi

# https://github.com/direnv/direnv/wiki/Python#uv
if ! config_mark "$DIRENVRC"; then
	log_verbose "Updating $DIRENVRC"
	config_add "$DIRENVRC" <<-'EOF'

		layout_uv() {
		    if [[ -d ".venv" ]]; then
		        VIRTUAL_ENV="$(pwd)/.venv"
		    fi
		    if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
		        log_status "No virtual environment exists. Executing \`uv venv\` to create one."
		        uv venv
		        VIRTUAL_ENV="$(pwd)/.venv"
		    fi
		    PATH_add "$VIRTUAL_ENV/bin"
		    export UV_ACTIVE=1  # or VENV_ACTIVE=1
		    export VIRTUAL_ENV
		}

		layout_anaconda() {
		  local ACTIVATE="${HOME}/miniconda3/bin/activate"
		  if [ -n "$1" ]; then
		    # Explicit environment name from layout command.
		    local env_name="$1"
		    source $ACTIVATE ${env_name}
		  elif (grep -q name: environment.yml); then
		    # Detect environment name from `environment.yml` file in `.envrc` directory
		    source $ACTIVATE `grep name: environment.yml | sed -e 's/name: //' | cut -d "'" -f 2 | cut -d '"' -f 2`
		  else
		    (>&2 echo No environment specified);
		    exit 1;
		  fi;
		}

		layout_poetry() {
		    PYPROJECT_TOML="${PYPROJECT_TOML:-pyproject.toml}"
		    if [[ ! -f "$PYPROJECT_TOML" ]]; then
		        log_status "No pyproject.toml found. Executing \`poetry init\` to create a \`$PYPROJECT_TOML\` first."
		        poetry init
		    fi
		    if [[ -d ".venv" ]]; then
		        VIRTUAL_ENV="$(pwd)/.venv"
		    else
		        VIRTUAL_ENV=$(poetry env info --path 2>/dev/null ; true)
		    fi
		    if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
		        log_status "No virtual environment exists. Executing \`poetry install\` to create one."
		        poetry install
		        VIRTUAL_ENV=$(poetry env info --path)
		    fi
		    PATH_add "$VIRTUAL_ENV/bin"
		    export POETRY_ACTIVE=1  # or VENV_ACTIVE=1
		    export VIRTUAL_ENV
		}
	EOF
fi

log_warning "To enable direnv in every directory with a .envrc run direnv allow there"
log_warning "To set .tool-versions run asdf direnv set golang 1.23 do not use asdf set"
