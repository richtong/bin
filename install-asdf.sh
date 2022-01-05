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
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs asdf multiple runtime version management
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
# 3.10 does not install properly as of Jan 2022 on Big Sur 11.6.2
declare -A ASDF+=(
	[direnv]=latest
	[nodejs]=latest
	[python]=latest
)

# http://asdf-vm.com/guide/getting-started.html#_3-install-asdf
if ! config_mark; then
	log_verbose "installing into profile"
	config_add <<-'EOF'
		# shellcheck disable=SC1091
		source "$(brew --prefix asdf)/libexec/asdf.sh"
	EOF
	# https://linuxhint.com/associative_array_bash/
	if [[ -n ${ASDF[direnv]} ]]; then
		log_verbose "Found direnv installing config info"
		config_add <<-'EOF'
			eval "$(asdf exec direnv hook bash)"
			direnv() { asdf exec direnv "$@"; }
		EOF
	fi
fi

# https://github.com/asdf-vm/asdf-nodejs/issues/253
log_verbose "must source otherwise reshim will fail"
source_profile

for p in "${!ASDF[@]}"; do
	log_verbose "install asdf plugin $p"
	if ! asdf list "$p" >/dev/null; then
		log_verbose "Install asdf plugin $p"
		asdf plugin add "$p"
	fi
	log_verbose "Is version installed for $p"
	version="$(asdf list "$p" 2>&1)"
	if [[ $version =~ "No versions" || ! $version =~ ${ASDF[$p]} ]]; then
		log_verbose asdf install "$p" "${ASDF[$p]}"
		asdf install "$p" "${ASDF[$p]}"
	fi
	log_verbose "Set global for $p with ${ASDF[$p]}"
	asdf global "$p" "${ASDF[$p]}"
done

# https://github.com/asdf-community/asdf-direnv
DIRENVRC="${DIRENVRC:-"$HOME/.config/direnv/direnvrc"}"
if ! config_mark "$DIRENVRC"; then
	log_verbose "adding to $DIRENVRC"
	config_add "$DIRENVRC" <<-'EOF'
		source "$(asdf direnv hook asdf)"
		# make direnv silent by default
		export DIRENV_LOG_FORMAT=""
	EOF
fi

ENVRC="${ENVRC:-"$HOME/.envrc"}"
if ! config_mark "$ENVRC"; then
	log_verbose "Adding $ENVRC"
	direnv allow "$ENVRC"
	config_add "$ENVRC" <<-'EOF'
		use asdf
	EOF
fi
