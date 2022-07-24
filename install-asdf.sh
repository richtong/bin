#!/usr/bin/env bash
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
NODE_VERSION="${NODE_VERSION:-latest}"
DIRENV_VERSION="${DIRENV_VERSION:-latest}"
PYTHON_VERSION="${PYTHON_VERSION:-latest}"
# openjdk18 is Java 8 for Unifi.app
JAVA_VERSION="${JAVA_VERSION:-openjdk-18}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvn:e:p:j:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs asdf multiple runtime version management
			    usage: $SCRIPTNAME [ flags ]
				flags: -h help
				   -d $($DEBUGGING || echo "no ")debugging
				   -v $($VERBOSE || echo "not ")verbose
			                   -p Python version (default: $PYTHON_VERSION)
			                   -e Direnv version (default: $DIRENV_VERSION)
			                   -n Node.js version (default: $NODE_VERSION)
			                   -j Java version (default: $JAVA_VERSION)

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
		PYTHON_VERSION="$OPTARG"
		;;
	e)
		DIRENV_VERSION="$OPTARG"
		;;
	n)
		NODE_VERSION="$OPTARG"
		;;
	j)
		JAVA_VERSION="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

if ! in_os mac; then
	# obsoleted by official 1passworld cli
	# https://app-updates.agilebits.com/product_history/CLI
	## https://www.npmjs.com/package/onepass-cli for npm package
	# git_install_or_update 1pass georgebrock
	log_exit "Mac only"
fi

log_verbose "Install asdf core"
package_install asdf
package_install gpg gawk

# https://stackoverflow.com/questions/28725333/looping-over-pairs-of-values-in-bash
declare -A ASDF+=(
	[direnv]=$DIRENV_VERSION
	[nodejs]=$NODE_VERSION
	[python]=$PYTHON_VERSION
	[java]=$JAVA_VERSION
)

# http://asdf-vm.com/guide/getting-started.html#_3-install-asdf
if ! config_mark "$(config_profile_nonexportable)"; then
	log_verbose "installing into profile"
	config_add "$(config_profile_nonexportable)" <<-'EOF'
		# shellcheck disable=SC1091
		        if command -v asdf >/dev/null; then
		                    # shellcheck disable=SC1090
		                    source "$(brew --prefix asdf)/libexec/asdf.sh"
		                fi
	EOF
	# https://linuxhint.com/associative_array_bash/
fi

# not clear what this is so as login shell should go into .zprofile
# for efficiency but leave in .zshrc as non-interactive
if ! config_mark "$(config_profile_nonexportable_zsh)"; then
	log_verbose "installing into .zshrc nonexportable"
	# no longer need manual installation
	asdf direnv setup --shell zsh --version "$((ASDF[direnv]))"
	#config_add "$(config_profile_zsh)" <<-'EOF'
	#    # shellcheck disable=SC1090
	#    source "$(brew --prefix asdf)/libexec/asdf.sh"
	#EOF
fi

if [[ -n ${ASDF[direnv]} ]]; then
	log_verbose "Found direnv installing config info"
	for SHELL_VERSION in bash zsh; do
		asdf direnv setup --shell "$SHELL_VERSION" --version "$((ASDF[direnv]))"
	done
	#config_add <<-'EOF'
	#    eval "$(asdf exec direnv hook bash)"
	#    direnv() { asdf exec direnv "$@"; }
	#EOF
fi

# https://github.com/asdf-vm/asdf-nodejs/issues/253
log_verbose "must source otherwise reshim will fail"
source_profile

for p in "${!ASDF[@]}"; do
	log_verbose "install asdf plugin $p"
	if ! asdf list "$p" >/dev/null; then
		log_verbose "Install asdf plugin $p"
		asdf plugin-add "$p"
	fi
	log_verbose "Is version installed for $p"
	version="$(asdf list "$p" 2>&1)"
	if [[ $version =~ "No versions" || ! $version =~ ${ASDF[$p]} ]]; then
		log_verbose asdf install "$p" "${ASDF[$p]}"
		# broken as of feb 2021
		#if in_os mac && ! mac_is_arm && [[ $p =~ python ]]; then
		#    log_verbose "Current bug in asdf python install skipping"
		#    continue
		#fi
		asdf install "$p" "${ASDF[$p]}"
	fi
	log_verbose "Set global for $p with ${ASDF[$p]}"
	asdf global "$p" "${ASDF[$p]}"
done

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
	direnv allow "$ENVRC"
	config_add "$ENVRC" <<-'EOF'
		use asdf
	EOF
fi

# https://github.com/halcyon/asdf-java#java_home
if ! config_mark; then
	config_add <<-'EOF'
		source "$HOME/.asdf/plugins/java/set-java-home.bash"
	EOF
fi

if ! config_mark "$(config_profile_nonexportable_zsh)"; then
	config_add "$(config_profile_nonexportable_zsh)" <<-'EOF'
		        source "$HOME/.asdf/plugins/java/set-java-home.zsh"
	EOF
fi

if ! config_mark "$HOME/.asdfrc"; then
	config_add "$HOME/.asdfrc" <<-'EOF'
		        java_macos_integration_enable = yes
	EOF
fi

log_warning "Please run 'asdf reshim' to install the plugins"
log_warning "To enable direnv in every directory with a .envrc run direnv allow there"
