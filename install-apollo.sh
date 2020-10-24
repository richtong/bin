#!/usr/bin/env bash
##
## Install Apollo from Baidu
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
OVA_URL="${OVA_URL:-https://bj.bcebos.com/apollo-open-data/apollo_cloud_ova?authorization=bce-auth-v1%2F32a3c819497c4a3a948949437610ba6d%2F2017-07-01T16%3A26%3A46Z%2F-1%2F%2F56e01ce25ca0f8a5695bec7690694d5ccc0549c45e7216814bffc2defac9c7bb}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvo:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Apollo
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug,verbose -v verbose, -h help"
			           -o Virtuabox OVA_URL image with Apollo
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
	o)
		OVA_URL="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh
if ! in_os linux; then
	log_exit "Linux only"
fi

if ! has_nvidia; then
	log_exit "Requires nVidia graphics"
fi

"$SCRIPT_DIR/install-virtualbox.sh"

# https://askubuntu.com/questions/843779/virtualbox-run-an-ova-file-from-command-line
log_verbose "starting download of $OVA_URL"
OVA_NAME="$(basename "$OVA_URL" | sed "s/\?.*//").ova"
log_verbose "$OVA_NAME to be downloaded"
OVA="${OVA:-"$WS_DIR/cache/$OVA_NAME"}"
log_verbose "importing $OVA"
download_url "$OVA_URL" "$OVA"
log_verbose "$OVA_URL downloaded"
vboxmanage import "$OVA"

# http://www.techrepublic.com/article/how-to-run-virtualbox-virtual-machines-from-the-command-line/
vboxmanage startvm apollo-cloud-demo --type headless
