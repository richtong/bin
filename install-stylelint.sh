#!/usr/bin/env bash
##
## Install stylelint for PostCSS and advanced checking since csslint does not
## handle PostCSS
##
## Seems to have trouble finding ~/.stylelintrc as it likes to have stylelintrc
## in the current directory for a stylelint property in package.json
## a .stylelintrc file or a stylelint.config.js
## It uses cosmicconfig to find this and it will up the tree to $HOME
## But it seems to have some caching problems
## https://github.com/stylelint/stylelint/blob/master/docs/user-guide/configuration.md
##
## https://github.com/stylelint/stylelint/blob/master/docs/user-guide/example-config.md
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
FORCE=${FORCE:-false}
LINT_FLAGS="${LINT_FLAGS:-""}"
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install Stylelint
			flags: -d debug, -v verbose, -h help
			       -f force install (default: $FORCE)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	f)
		FORCE=true
		LINT_FLAGS=" -f "
		;;
	*)
		echo >&2 "$SCRIPTNAME: -$opt not valid"
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-config.sh

shift $((OPTIND - 1))

NODE_ROOT="$(command -v node)"
NODE_ROOT="${NODE_ROOT%/*/*}"
log_verbose "NODE_ROOT is $NODE_ROOT"
#if [[ $OSTYPE =~ darwin ]]
#then
#    log_verbose on Darwin node root is two above the command
#    #NODE_ROOT=/opt/local
#else
#    NODE_ROOT=/usr
#fi

# 150 rules so use a default
# https://www.sitepoint.com/improving-the-quality-of-your-css-with-postcss/
npm_install -g stylelint stylelint-config-standard

# we want the flag to not exist and be globbed
# shellcheck disable=SC2086
if ! config_mark $LINT_FLAGS "$HOME/.stylelintrc" "added:"; then
	log_verbose adding lines to .stylelintrc
	config_add "$HOME/.stylelintrc" <<<"extends : $NODE_ROOT/lib/node_modules/stylelint-config-standard"
fi
# old interface moved to new
#config_add_lines "$FORCE" "Added by $SCRIPTNAME" "$HOME/.vimrc" \
#    '"' \
#    "let g:syntastic_css_checkers = [ 'stylelint' ]"
log_verbose checking .vimrc

# we want the flag to not exist and be globbed
# shellcheck disable=SC2086
if ! config_mark $LINT_FLAGS "$HOME/.vimrc" '"'; then
	log_verbose adding lines to .vimrc
	config_add "$HOME/.vimrc" <<<"let g:syntastic_css_checkers = [ 'stylelint' ]"
fi
