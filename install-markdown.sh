#!/usr/bin/env bash
##
## Markdown utilities
## https://github.com/thlorenz/doctoc
## There are two markdownlinters mdl is ruby and markdown-cli is from node
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
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Markdown utilities
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -r version number (default: $VERSION)
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

source_lib lib-install.sh lib-util.sh

NPM=" doctoc "

# We want to allow splitting by white space for packages
#shellcheck disable=SC2086
npm_install -g $NPM

# https://github.com/igorshubovych/markdownlint-cli
log_verbose "Installing markdownlint-cli the nodejs version as markdownlint"
log_verbose "Installing markdownlint-cli2 which has a different interface for VSCode"
log_verbose "Use with repo: pointed to https://github.com/igorshubovych/markdownlint-cli"
package_install markdownlint-cli markdownlint-cli2

# https://dev.to/jonasbn/blog-post-markdownlint-24ig
log_verbose "Installing markdownlint the ruby version as mdl"
# https://github.com/markdownlint/markdownlint/blob/master/.pre-commit-hooks.yaml
log_verbose "compatible with pre-commit with entrypoint mdl"
gem_install mdl
