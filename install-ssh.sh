#!/usr/bin/env bash
##
## install openssh  iuncluding the server
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
export FLAGS=${FLAGS:-" -v "}
VERSION="${VERSION:-"7.5p1"}"
URL="${URL:-"https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$VERSION.tar.gz"}"
PGP_URL="${PGP_URL:-"$URL.asc"}"
# https://www.openssh.com/portable.html
SIGNER_URL="${SIGNER_URL:-"https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/RELEASE_KEY.asc"}"
while getopts "hdvm:r:u:c:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Install Openssh and the Server too
			usage: $SCRIPTNAME [ flags ]

			flags: -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
			       -r desired version number (default: $VERSION)
			       -u download if necessary from this Url (default: $(eval echo "$URL"))
			       -c PGP_URL checksum for url (default from : $(eval echo "$PGP_URL"))
			          set to zero if do not want checksum validation
			       -s PGP Signer pullic key (default from : $SIGNER_URL)

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
	u)
		URL="$OPTARG"
		;;
	m)
		PGP_URL="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh lib-version-compare.sh lib-avahi.sh

# do not use the homebrew openssh because it does understand Apple Keychain
if ! in_os mac; then
	log_verbose "Install homebrew openssh"
	package_install openssh
	log_verbose "openssh installed now rehash to add to script path"
	hash -r
fi

current_version=$(ssh -V 2>&1 | cut -d ' ' -f 1 | cut -d '_' -f 2)
# https://gist.github.com/techgaun/df66d37379df37838482c4c3470bc48e
if vergte "$current_version" "$VERSION"; then
	if in_os linux; then
		log_verbose "For linux install manually avahi services"
		# %h means substitute the current hostname
		log_verbose "advertise an ssh avahi service"
		avahi_publish ssh "%h" "_ssh._tcp" 22 "SSH Server"
		log_verbose "advertise an sftp over ssh service"
		avahi_publish sftp-ssh "%h" "_sftp-ssh._tcp" 22 "SFTP over SSH Server"
	fi
	log_exit "Succes $current_version is greater or equal to desired $VERSION"
fi

if in_os mac; then
	log_exit "Could not get desired version on Mac"
fi

log_warning "the repo version is too old, doing a manual install but you will not"
log_warning "get updates from this version"

package_install build-essential libssl-dev zlib1g-dev

log_verbose finding PGP

for url in URL PGP_URL SIGNER_URL; do
	# double eval allows variable indirection
	# first eval set the variable second handles
	# second eval deals with variables in the url string
	eval eval $url=\$$url
	log_verbose "$url now set to $(eval echo \$$url)"
done

log_verbose "attempting to download from $URL"
download_url_pgp "$URL" "$PGP_URL" "$SIGNER_URL"

# http://www.linuxfromscratch.org/blfs/view/svn/postlfs/openssh.html
if ! pushd "$WS_DIR/cache" >/dev/null; then
	log_error 1 "no $WS_DIR/cache"
fi
tar_name="$(basename "$URL")"
log_verbose "now trying to extract $tar_name"
tar xfz "$tar_name"
dir_name="${tar_name%.tar.gz}"
log_verbose "go into $dir_name and configure and make"
if ! pushd "$dir_name" >/dev/null; then
	log_error 2 "no $dir_name"
fi
./configure
make
sudo make install
popd >/dev/null || true
