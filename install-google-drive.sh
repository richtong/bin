#!/usr/bin/env bash
##
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
			Installs Google Drive
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
source_lib lib-mac.sh lib-install.sh lib-util.sh

if in_os mac; then
	package_install google-drive
	log_exit
fi

# gnome-online accounts give a file manager view but then GUIDs only
package_install rclone gnome-online-accounts

log_verbose "You will need to create a google client id and an oauth id"
log_verbose "Put these into 1Password so you can find this"
log_verbose "Run rclone config and enter the name as say app:"
log_verbose "use rclone sync to put this into $WS_DIR/data"

# deprecated for rclone
# 	log_warning "Go to user interface and Settings > Online Accounts > Google Accounts"
# 	log_verbose "Install OCAML Fuse driver"
# 	# https://support.shells.net/hc/en-us/articles/1500008874361-How-to-connect-to-Google-Drive-using-FUSE-filesystem-in-Your-Ubuntu-Shell
# 	apt_repository_install "ppa:allessandro-strada/ppa"
# 	package_install google-drive-ocamlfuse
# 	google-drive-coamlfuse
# 	mkdir -p "$HOME/Google Drive"
# 	google-drive-ocamfuse "$HOME/Google Drive"
# fi
