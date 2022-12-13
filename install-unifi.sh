#!/usr/bin/env bash
##
## Install Unifi Apps and optionally the Unifi Controllerj
## As of version 4.11.47 needs Java 8
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

VERSION="${VERSION:-8}"
export FLAGS="${FLAGS:-""}"
CONTROLLER="${CONTROLLER:-false}"

while getopts "hdvr:c" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Unifi and the prerequisites which is Java 8
			    usage: $SCRIPTNAME [ flags ]
			    flags: -h help"
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
				   -c $(! $CONTROLLER || echo "do not ")install UniFi Controller
			                   -r Java version for UniFi Controller (default: $VERSION)
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
	c)
		CONTROLLER="$($CONTROLLER && echo false || echo true)"
		;;
	r)
		VERSION="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-mac.sh lib-install.sh

if [[ ! $OSTYPE =~ darwin ]]; then
	log_exit "Mac only"
fi

if mac_is_arm; then
	log_verbose "Install iPhone Apps on Apple Silicon"
	# WiFiMan
	MAS+=(1385561119)

	mas_install "${MAS[@]}"
fi

if $CONTROLLER; then
	log_verbose "Install UniFi Controller locally"
	cask_install ubiquiti-unifi-controller
	log_verbose make sure we are running Java 8 which is really called version 1.8
	"$SCRIPT_DIR/install-java.sh" -r "$VERSION"

	if ! pushd "/Applications/UniFi.app/Contents/Java" >/dev/null; then
		log_error 1 "no Unifi.app"
	fi

	# use asdf instead
	asdf local java openjdk-18
	#sudo jenv local 1.8

	log_verbose "Running UniFi.app requires Oracle Java 1.8 download"
	# https://ars-codia.raphaelbauer.com/2021/01/running-ubiquiti-unifi-controller-on.html
	log_verbose "To run manually cd to /Applications/UniFi.app/Content/Resources"
	log_verbose "java -jar lib/ace.jar start"
	log_verbose "browse to https://localhost:8443"
fi
