#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install Fig the completion helper
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
VERSION="${VERSION:-7}"
EMAIL="${EMAIL:-rich@tongfamily.com}"
SIGNIN="${SIGNIN:-my}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvr:e:s:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Fig.io
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
				   -r version number (default: $VERSION)
				   -e email for login (default: $EMAIL)
				   -s signin subdomain add to .1password.com (default: $SIGNIN)
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
	r)
		VERSION="$OPTARG"
		;;
	e)
		EMAIL="$OPTARG"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-util.sh lib-install.sh lib-config.sh

if in_os linux; then

	# https://fig.io/user-manual/linux
	curl -SsL https://fig.io/install.sh | bash
	source_profile
	fig login

elif in_os mac; then

	brew_install fig
	open -a fig.app
	if ! config_mark; then
		config_add <<-'EOF'
			echo "$PATH" | grep -q ".fig/bin" || PATH="$HOME/.fig/bin:$PATH"
		EOF
	fi
	log_warning "This improperly puts bash script into .profile so delete manually"

fi
