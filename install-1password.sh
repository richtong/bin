#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## install 1Password
## @author Rich Tong
## @returns 0 on success
#
# https://news.ycombinator.com/item?id=9091691 for linux gui
# https://news.ycombinator.com/item?id=8441388 for cli
# https://www.npmjs.com/package/onepass-cli for npm package
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
			Installs 1Password
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

# just source if we are running in a mountable drive
if [[ $SCRIPT_DIR =~ /Volumes ]]; then
	# shellcheck disable=SC1091
	source lib-git.sh lib-mac.sh lib-install.sh lib-util.sh
else
	source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh
fi

if in_os linux && linux_version ubuntu; then

	if SANDBOX; then
		log_verbose "Install Linux graphical 1Password without cli or ssh-agent"
		flatpak_install 1password
		log_verbose "Also install the browser extensions manually"
	else
		curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
		echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
		sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
 curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
 sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
 curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
		sudo apt update && sudo apt install 1password
	fi


elif in_os mac; then

	if [[ -n $(find /Applications -maxdepth 1 -name "1Password*" -print -quit) ]]; then
		log_verbose "1Password for Mac already installed"
		exit
	fi

	log_verbose using brew to install on Mac 1Password and the CLI
	if package_install 1password; then
		for PROFILE in "" "$(config_zsh_profile)"; do
			# shellcheck disable=SC2086
			if ! config_mark $PROFILE; then
				# shellcheck disable=SC2086
				config_add $PROFILE <<-EOF
					if command -v op >/dev/null && [[ ! -v OP_SESSION_$SIGNIN ]]; then
						eval "\$(op $SIGNIN.1password.com $EMAIL)"; fi
				EOF
			fi
		done
		log_verbose "Install 1password for safari"
		mas install 1569813296
		log_exit "installed 1password 1password-cli and safari add-on"
	fi

	log_verbose "brew install failed trying to download the package"
	# download_url_open "https://d13itkw33a7sus.cloudfront.net/dist/1P/mac4/1Password-6.0.2.zip"
	# more general location
	# usage: download_url url [dest_file [dest_dir [md5 [sha256]]]]
	# Have to increment the OPM number as versions increase
	log_verbose "installed 1Password Version $VERSION"
	download_url_open "https://app-updates.agilebits.com/download/OPM$VERSION" "1Password.pkg"

fi

PACKAGE+=(
	1password-cli
)

log_verbose "Install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

# https://developer.1password.com/docs/cli/shell-plugins/github/
log_verbose "Enable command line integrations to store credentials in 1Password"

# you only need brew if you are hitting the github api rate limit when
# searching
# brew
PLUGIN+=(
	aws
	doctl
	gh
)

# this creates a ./.op directory in the CWD so make sure we are at HOME
WORKING_DIR="$PWD"
if ! pushd "$HOME" >/dev/null; then
	log_warning "Could not go to HOME $HOME will create .op in $CWD"
	PUSHED=true
fi
for PLUG in "${PLUGIN[@]}"; do
	log_verbose "Installing $PLUG"
	op plugin "$PLUG"
done
if $PUSHED && ! popd >/dev/null; then
	log_warning "Could not return to execution directory $WORKING_DIR"
fi

if ! config_mark "$(config_profile_nonexportable)"; then
	config_add "$(config_profile_nonexportable)" <<-EOF
		if [[ -e $HOME/.config/op/plugins.sh ]]; then . "$HOME/.config/op/plugins.sh"; fi
	EOF
fi
