#!/usr/bin/env bash
##
## install Veracrypt
## https://apple.stackexchange.com/questions/230520/how-to-execute-veracrypt-on-the-command-line
## https://veracrypt.codeplex.com/wikipage?title=Command%20Line%20Usage
##@author Rich Tong

##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-" -v "}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Veracrypt the file encryption tool based on TrueCrypt
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"

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
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-mac.sh lib-version-compare.sh
shift $((OPTIND - 1))

if [[ $OSTYPE =~ darwin ]]; then
	log_verbose brew cask installation
	if vergte "$(mac_version)" 10.13 && command -v virtualbox; then
		log_warning on High Sierra, virtualbox and osxfuse used by veracrypt and sshfs cannot run together
		log_warning or remove a kext that uses a file driver slot see https://github.com/osxfuse/osxfuse/issues/315#issuecomment-258456598
		log_warning 1 "you need to uninstall brew cask uninstall virtualbox"
	fi

	cask_install veracrypt
	if ! config_mark; then
		config_add <<-EOF
			[[ -e /Applications/VeraCrypt.app/Contents/MacOS ]] && PATH+=":/Applications/VeraCrypt.app/Contents/MacOS"
		EOF
	fi
	log_exit "Veracrypt installed"
fi

# https://www.linuxbabe.com/ubuntu/install-veracrypt-ubuntu-16-04-16-10
log_verbose installing repo
repository_install ppa:unit193/encryption
log_verbose installing veracrypt

if vergte "$(mac_version)" 10.13; then
	log_warning require OSXFuse kext and you will see a dialog but may not
	log_warning see the checkbox, you will need to reboot and to see it
fi

package_install veracrypt
