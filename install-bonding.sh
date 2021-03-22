#!/usr/bin/env bash
##
## Install bonding aka as link aggregation
## Requires multiple ethernet ports on the server
## Uses  IEEE 802.3ad LACP bonding protocol:
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
FORCE=false
while getopts "hdvf:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install bonding aka link aggregation"
		echo "flags: -d debug, -h help"
		echo "       -f force this configuration over Network Manager (default: $FORCE"
		echo -n "positionals:"
		netstat -i | grep -o "eth[0-9]*"
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
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-config.sh lib-git.sh lib-util.sh
shift $((OPTIND - 1))

# pulls things assuming your git directory is $WS_DIR/git a la Sam's convention
# There is an optional 2nd parameter for the repo defaults to $ORG_NAME

if ! in_os linux; then
	log_error 1 "only works on ubuntu"
fi

if [[ -z "$*" ]]; then
	log_error 2 "need to enter some network interfaces"
fi

if ! $FORCE && is_package_installed network_manager; then
	log_message "To use Network Manager, choose the Add Network and select Bond"
	log_message "Chose Add Interface for each Mac id you want and make sure to go to general tab and select access if available"
	log_message "Choose the Bond General tab and do the same and remove the individual interfaces at the top"
	log_error 3 "incompatible with ubuntu network manager use bond gui"

fi

log_warning "do not run this from ssh we will bring the network down now"

sudo stop networking

package_install ifenslave
log_verbose adding bonding to /etc/modules
config_add_once /etc/modules bonding

mod_install bonding

# https://joekuan.wordpress.com/2009/11/01/awk-scripts-for-reading-and-editing-ubuntu-etcnetworkinterfaces-file-part-22/
if ! git_install_or_update Network-Interfaces-Script JoeKuan; then
	log_warning network down keep trying assume you setup lacp on switch first
fi

interfaces=""
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for i in "$@"; do
	# http://www.cyberciti.biz/faq/linux-list-network-interfaces-names-command/
	if ! netstat -i | grep -q "^$i"; then
		log_warning 1 "$i is not a network interface ignoring"
	fi
	interfaces+=" $i"
done

if ! config_mark /etc/network/interfaces; then

	log_verbose turns off Ubuntu Network Manager only for interfaces mentioned in /etc/network/interfaces
	config_add /etc/network/interfaces <<-EOF
		[main]
		plugins=ifupdown

		[ifupdown]
		managed=false
	EOF
fi

for i in $interfaces; do
	awk -f "$WS_DIR/git/Network-Interfaces-Script/changeInterface.awk" \
		/etc/network/interfaces \
		"dev=$i" mode=remove

	config_add /etc/network/interfaces <<-EOF
		auto $i
		iface $i net manual
		bond-master bond0

	EOF

done

config_add /etc/network/interfaces <<-EOF
	# bond-mode 4 is 802.3ad
	auto bond0
	iface bond0 net dhcp
	bond-mode 4
	bond-miimon 100
	bond-lacp-rate 1
	bond-slaves $@

EOF

log_verbose start network
sudo start networking

if $VERBOSE; then
	cat proc/net/bonding/bond0
fi
