#!/usr/bin/env bash
##
## install divvy a tile window manager for Mac
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install Divvy for MacOS"
		echo "flags: -d debug, -v verbose, -h help"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh

set -u
shift $((OPTIND - 1))

if ! in_os mac; then
	log_exit "Only for Mac"
fi

if [[ -e /Applications/Divvy.app ]]; then
	log_exit "Divvy already installed"
fi

log_verbose try brew cask to install divvy
if ! cask_install divvy; then
	log_verbose cask install failed trying direct download
	download_url_open "http://mizage.com/downloads/Divvy.zip"
fi

open "/Applications/Divvy.app"

log_verbose Adding standard shortcuts 1,2,3,4 for quarter screens
log_verbose 5,6,...0 for thirds
open "divvy://import/YnBsaXN0MDDUAQIDBAUGy8xYJHZlcnNpb25YJG9iamVjdHNZJGFyY2hpdmVyVCR0b3ASAAGGoK8QJAcIHTQ1PEZHT1BYWWFiamtzdHx9hYaPkJiZoqOrrLS1vb7Gx1UkbnVsbNIJCgscWk5TLm9iamVjdHNWJGNsYXNzrxAQDA0ODxAREhMUFRYXGBkaG4ACgAWAB4AJgAuADYAPgBGAE4AVgBeAGYAbgB2AH4AhgCPdHh8gISIKIyQlJicoKSorLC0uLysuKjEyLDNYc2l6ZVJvd3NfEA9zZWxlY3Rpb25FbmRSb3dfEBFzZWxlY3Rpb25TdGFydFJvd1pzdWJkaXZpZGVkVmdsb2JhbF8QEnNlbGVjdGlvbkVuZENvbHVtbldlbmFibGVkW3NpemVDb2x1bW5zV25hbWVLZXlca2V5Q29tYm9Db2RlXxAUc2VsZWN0aW9uU3RhcnRDb2x1bW5da2V5Q29tYm9GbGFncxAGEAIQAAgJgAQJgAMQEhIAHAAAWFRvcCBMZWZ00jY3ODlaJGNsYXNzbmFtZVgkY2xhc3Nlc1hTaG9ydGN1dKI6O1hTaG9ydGN1dFhOU09iamVjdN0eHyAhIgojJCUmJygpKissLS4vQC4qQkNERQgJgAQQBQmABhATEAMSABwAAFlUb3AgUmlnaHTdHh8gISIKIyQlJicoKSpARC0uLysuKkxNLE4ICYAECYAIEBQSABwAAFtCb3R0b20gTGVmdN0eHyAhIgojJCUmJygpKkBELS4vQC4qVVZEVwgJgAQJgAoQFRIAHAAAXEJvdHRvbSByaWdodN0eHyAhIgojJCUmJygpKkAsLS4vKy4qXl8sYAgJgAQJgAwQexIAnAAAVExlZnTdHh8gISIKIyQlJicoKSpALC0uL0AuKmdoRGkICYAECYAOEHwSAJwAAFVSaWdodN0eHyAhIgojJCUmJygpKissLS4vQC4qcHEscggJgAQJgBAQfhIAnAAAU1RvcN0eHyAhIgojJCUmJygpKkBELS4vQC4qeXosewgJgAQJgBIQfRIAnAAAVkJvdHRvbd0eHyAhIgojJCUmJygpKkAsLS4vQC4qgoMshAgJgAQJgBQQLhIAHAAAWE1heGltaXpl3R4fICEiCiMkJSYnKCkqKywtLi+KLiqMjSyOCAmABBABCYAWEBcSABwAAF5Ub3AgTGVmdCBUaGlyZN0eHyAhIgojJCUmJygpKissLS4vRC4qlZYrlwgJgAQJgBgQFhIAHAAAXxAQVG9wIENlbnRlciBUaGlyZN0eHyAhIgojJCUmJygpKissLS4vQC4qnp+goQgJgAQJgBoQGhAEEgAcAABfEA9Ub3AgUmlnaHQgVGhpcmTdHh8gISIKIyQlJicoKSpARC0uL4ouKqipLKoICYAECYAcEBwSABwAAF8QEUJvdHRvbSBMZWZ0IFRoaXJk3R4fICEiCiMkJSYnKCkqQEQtLi9ELiqxsiuzCAmABAmAHhAZEgAcAABfEBNCb3R0b20gQ2VudGVyIFRoaXJk3R4fICEiCiMkJSYnKCkqQEQtLi9ALiq6u6C8CAmABAmAIBAdEgAcAABfEBFCb3R0b20gTGVmdCBUaGlyZN0eHyAhIgojJCUmJygpKqCKLS4voC4qw8SKxQgJgAQJgCIQCBIAHAAAVkNlbnRlctI2N8jJXk5TTXV0YWJsZUFycmF5o8jKO1dOU0FycmF5XxAPTlNLZXllZEFyY2hpdmVy0c3OVHJvb3SAAQAIABEAGgAjAC0AMgA3AF4AZABpAHQAewCOAJAAkgCUAJYAmACaAJwAngCgAKIApACmAKgAqgCsAK4AsADLANQA5gD6AQUBDAEhASkBNQE9AUoBYQFvAXEBcwF1AXYBdwF5AXoBfAF+AYMBjAGRAZwBpQGuAbEBugHDAd4B3wHgAeIB5AHlAecB6QHrAfAB+gIVAhYCFwIZAhoCHAIeAiMCLwJKAksCTAJOAk8CUQJTAlgCZQKAAoECggKEAoUChwKJAo4CkwKuAq8CsAKyArMCtQK3ArwCwgLdAt4C3wLhAuIC5ALmAusC7wMKAwsDDAMOAw8DEQMTAxgDHwM6AzsDPAM+Az8DQQNDA0gDUQNsA20DbgNwA3IDcwN1A3cDfAOLA6YDpwOoA6oDqwOtA68DtAPHA+ID4wPkA+YD5wPpA+sD7QPyBAQEHwQgBCEEIwQkBCYEKAQtBEEEXARdBF4EYARhBGMEZQRqBIAEmwScBJ0EnwSgBKIEpASpBL0E2ATZBNoE3ATdBN8E4QTmBO0E8gUBBQUFDQUfBSIFJwAAAAAAAAIBAAAAAAAAAM8AAAAAAAAAAAAAAAAAAAUp"
