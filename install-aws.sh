#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## install the Amazon AWS components
## Use standard build environment layout
## Expects there to be aws keys in a key file
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# get command line options
OPTIND=1
DOWNLOAD="${DOWNLOAD:-false}"
APT_INSTALL=${APT_INSTALL:-false}
while getopts "hdvbf" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: install aws"
		echo "flags: -d : debug, -v : verbose, -h :help"
		echo "       -b use deprecated apt-get installer (default: $APT_INSTALL)"
		echo "  	 -f download directly from AWS (default: $DOWNLOAD)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	b)
		APT_INSTALL=true
		;;
	f)
		DOWNLOAD=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND - 1))
source_lib lib-install.sh lib-util.sh

#if command -v aws >/dev/null; then
#log_exit "installed already $(aws --version)"
#fi
PACKAGE+=(
	awscli
	aws-cdk
	s3cmd
)

log_verbose "Installing ${PACKAGE[*]}"
if package_install "${PACKAGE[@]}"; then
	log_exit "Installed ${PACKAGE[*]}"
fi

if in_os mac; then
	log_verbose "installing awscli if brew install failed"
	if ! command -v aws && [[ $(command -v python) =~ /opt/local ]]; then
		log_warning running with Macport python and this does not seem to work but try anyway
		# https://trac.macports.org/ticket/50063
		# https://trac.macports.org/ticket/49575 has a manual dependency on docutils
		if command -v port; then
			sudo port install py27-awscli awscli_select py27-docutils
			sudo port select awscli py27-awscli
		fi
	fi
	log_exit "Mac installed"
fi

NODE_PACKAGE=(
	aws-cdk
)
log_verbose "Install ${NODE_PACKAGE[*]}"
npm_install -g "${NODE_PACKAGE[@]}"

log_verbose "Linux installation started"
if $APT_INSTALL; then
	# https://stackoverflow.com/questions/36969391/how-to-upgrade-aws-cli-to-the-latest-version
	log_verbose package install
	package_install awscli
	# pip_install --user --upgrade awscli
	log_exit "install awscli"

	if ! in_os docker; then
		# Debian does not have ntpdate by default
		if ! command -v ntpdate; then
			log_verbose ntp install
			package_install ntpdate
		fi
		# VMware can get out of date so force a time update
		log_verbose Need to time synchronize because aws will not allow out of date clients
		# -u so it works on Mac too
		# http://osxdaily.com/2012/07/04/set-system-time-mac-os-x-command-line/
		sudo ntpdate -u pool.ntp.org
	fi

fi

if $DOWNLOAD; then
	# the only way in August 2020 to get AWS CLI v2 official way:w
	log_verbose bundled install as the last try
	download_url "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
		"awscliv2.zip"
	pushd >/dev/null "$WS_DIR/cache"
	log_verbose unpackaging awscli source
	package_install unzip
	unzip -oq awscliv2.zip
	log_verbose building aws cli from source
	if ! sudo ./aws/install; then
		log_warning "Installation failed do ypu and to upgrade instead"
	fi
	pushd >/dev/null
	log_exit bundle installed
# as of August 2020 no more pip install
# package_install python-pip
# http://docs.aws.amazon.com/cli/latest/userguide/installing.html
# --upgrade means update all requirements
# --user means install for current user only not for all users
# pip_install --upgrade --user awscli
# log_exit "pip install succeeded"

fi
