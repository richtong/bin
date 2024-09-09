#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
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
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Markdown utilities
			    usage: $SCRIPTNAME [ flags ]
			                flags:
				   -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
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
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

# doctoc replaced by markdown-toc which hides the toc unless needed
# doctoc - https://github.com/thlorenz/doctoc summarize all markdown files and
# creates a table of contents which is useful for standalone README.md
# but use mkdocs for bigger README is recommented
# markdownling-cli2 now has brew package so use that
# log_verbose "installing doctoc"
# doctoc
# NPM+=(
# )
# We want to allow splitting by white space for packages
#shellcheck disable=SC2086
# npm_install -g "${NPM[@]}"

log_verbose "Note: install-lint.sh installed mdformat-ruff and can use as mdformat"

# https://github.com/igorshubovych/markdownlint-cli
log_verbose "Installing markdownlint-cli the nodejs version as markdownlint"
log_verbose "Use with repo: pointed to https://github.com/igorshubovych/markdownlint-cli"
log_verbose "Install markdown which is basic markdown processor"
# https://github.com/DavidAnson/markdownlint-cli2/issues/6
# cli2 is supposed to be faster used by nvim
# markdown-toc generates a toc like doctotoc for lazyvim
# injects the toc at the comment
# <!-- toc -->
# Will replace the toc if it sees <!-- tocstop -->
PACKAGE+=(
	markdown
	markdownlint-cli
	markdownlint-cli2
	markdown-toc
	zettler
)

package_install "${PACKAGE[@]}"

# only using markdownllint-cli2 now
# https://dev.to/jonasbn/blog-post-markdownlint-24ig
# log_verbose "Installing markdownlint the ruby version as mdl for compatibility"
# https://github.com/markdownlint/markdownlint/blob/master/.pre-commit-hooks.yaml
# log_verbose "compatible with pre-commit with entrypoint mdl"
# "$SCRIPT_DIR/install-ruby.sh"
# gem_install mdl
