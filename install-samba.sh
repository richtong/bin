#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Installs Samba on base Ubuntu for the user files
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

SHARE_ROOT="${SHARE_ROOT:-/home}"
if [[ ! -v DEFAULT_SHARE ]]; then
	find /home -maxdepth 1 | cut -d '/' -f 3 | mapfile -t DEFAULT_SHARE
fi
if ((${#DEFAULT_SHARE[@]} > 0)); then SHARE=("${SHARE[@]}:-${DEFAULT_SHARE[@]}"); fi

OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Samba shares for the /home users
			usage: $SCRIPTNAME [ flags ]
				[ shares... ] (default: ${SHARE[*]})
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
				   -r Parent directory of shares (default: $SHARE_ROOT)
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
		SHARE_ROOT="$OPTARG"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-util.sh

if ! in_os linux; then
	log_exit "Linux only"
fi

package_install samba

if (($# > 0)); then
	log_verbose "Use $*"
	# shellcheck disable=SC2207
	SHARE=("$@")
fi

sudo touch /etc/samba/smb.conf

# https://itsubuntu.com/how-to-install-samba-on-ubuntu-20-04-lts/
# https://help.ubuntu.com/lts/serverguide/samba-fileserver.html
if ! config_mark /etc/samba/smb.conf; then
	for share in "${SHARE[@]}"; do
		config_add /etc/samba/smb.conf <<-EOF
			[$share]
				comment = $HOSTNAME Samba Share
				path = /$SHARE_ROOT/$share
				browsable = yes
				guest = ok
				writable = yes
				create mask = 0755
		EOF
	done
fi

log_verbose "Populated smb.conf now resetart service"
sudo service smdb restart
sudo restart nmbd

log_warning "You must also setup smb share passwords"
