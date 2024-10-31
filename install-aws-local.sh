#!/usr/bin/env bash
##
## Install sam local to run lambdas in a docker container
## https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-linux.html
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs AWS SAM Local and Local Stack for AWS testing on your
			machine
			    usage: $SCRIPTNAME [ flags ]
			    flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
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
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

tap_install aws/tap
PACKAGE=(
	aws/tap/aws-sam-cli
	localstack
)

log_verbose "Installing ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

PYTHON_PACKAGE=(
	awscli-local
)

log_verbose "Installing ${PYTHON_PACKAGE[*]}"
pipx_install "${PYTHON_PACKAGE[@]}"

NODE_PACKAGE=(
	aws-cdk-local
)

log_verbose "Installing ${NODE_PACKAGE[*]}"
npm_install -g "${NODE_PACKAGE[@]}"

# https://docs.localstack.cloud/getting-started/quickstart/
log_verbose "start localstack without paying otherwise you need "
log_berbose "LOCALSTACK_AUTH_TOKEN or soon be deprecated LOCALSTACK_API_KEY"
log_verbose with "ACTIVATE_PRO=0 localstack start"
log_verbose "see https://docs.localstack.cloud/getting-started/quickstart/"
