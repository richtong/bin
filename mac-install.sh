#!/usr/bin/env bash

## Install mac development packages
##
## vi: se ai sw=2 et:
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "$0")
trap 'exit $?' ERR # Need to use pwd and not readlink on Mac
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
FORCE="${FORCE:-false}"
# https://www.ubuntu.com/download/desktop as of August 2020
VMWARE="${VMWARE:-false}"
UBUNTU="${UBUNTU:-"20.04"}"
# https://www.debian.org/releases/ as of August 2020
DEBIAN="${DEBIAN:-"10.5"}"
PACKAGES="${PACKAGES:-""}"
SOFTWAREUPDATE="${SOFTWAREUPDATE:-false}"
MACPORTS_INSTALL="${MACPORTS_INSTALL:-false}"
# The other choice is zsh but this is not working yet
DESIRED_SHELL="${DESIRED_SHELL:-bash}"
OPTIND=1
while getopts "hdvw:fu:b:mpa:" opt; do
	case "$opt" in
	h)

		# use old style echo because this might run in MacOS Bash 3.x
		cat <<-EOF
			Install mac specific components
			usage: $SCRIPTNAME [flags]
			flags: -d debug, -v verbose, -h help
			       -w WS directory
			       -f force Mac system software update takes a long time "(default: $FORCE)"
			       -a Use VMware Fusion (default: $VMWARE)
			       -u Ubuntu version for Fusion "(default: $UBUNTU)"
			       -b Debian version for Fusion "(default: $DEBIAN)"
			       -m MacOS Software Update beware takes a long time "(default: $SOFTWAREUPDATE)"
			       -p Install Macports as well as Homebrew "(default: $MACPORTS_INSTALL)"
			       -s Install a new default shell either bash or zsh "(default: $DESIRED_SHELL)"
		EOF

		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	w)
		WS_DIR="$OPTARG"
		;;
	f)
		FORCE=true
		;;
	u)
		UBUNTU="$OPTARG"
		;;
	b)
		DEBIAN="$OPTARG"
		;;
	m)
		SOFTWAREUPDATE=true
		;;
	p)
		MACPORTS_INSTALL="$OPTARG"
		;;
	a)
		VMWARE=true
		;;
	*)
		echo "-$opt flag invalid" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

# must be after the include since WS_DIR defined there
DOWNLOADS=${DOWNLOADS:-"$WS_DIR/cache"}
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh
if [[ ! $OSTYPE =~ darwin ]]; then
	log_exit Must be on OS X does nothing otherwise
fi

# https://github.com/mathiasbynens/dotfiles/blob/master/.macos
# We don't implement it but there is a huge list of useful Mac defaults
# set by the defaults command
log_verbose set Finder to show all extensions, status bar and path
# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# After Mojave, need the commandline tools
# https://derflounder.wordpress.com/2018/06/10/updated-xcode-command-line-tools-installer-script-now-available/
# Now check first
# https://apple.stackexchange.com/questions/337744/installing-xcode-command-line-tools
if [[ $(xcode-select -p) == "" ]]; then
	xcode-select --install
fi

# Mac OS X uses Bash 3.2, we need 4.x
PACKAGES+=" bash "

# For lib-debug.sh gettext is in install-gnu.sh
# PACKAGES+=" gettext "

# For lib-config.sh
PACKAGES+=" lua "

# These are gnu utilities so installed by install-gnu.sh
# Updated basic as Mac OS X does not like GPL 3, need -i for sed
# PACKAGES+=" grep "
# PACKAGES+=" gnu-sed "
# gsed is the mac ports name
#PACKAGES+=" gsed "

# For editing and diagnosing videos vlc currently fails to build on Mac OS X
# on macports and is a cask on brew
# PACKAGES+=" vlc "

# To run commands in parallel across the cluster do not need anymore
# PACKAGES+=" parallel "

# http://blog.hypriot.com/post/introducing-hypriot-cluster-lab-docker-clustering-as-easy-as-it-gets/
# For hypriot RPI cluster searching
PACKAGES+=" nmap "

# docker users this for installation
PACKAGES+=" wget "

# use Brew for command line management of Mac App Store apps
# https://lifehacker.com/mas-updates-and-installs-mac-app-store-apps-from-the-co-1791919584
PACKAGES+=" mas "
log_verbose mas list for all installed apps
log_verbose mas outdated for apps needing upgrade
log_verbose "mas upgrade to update then all"
log_verbose mas search app_name will return the application identifier
log_verbose mas install app_number will install a specific app

# do not run softwareupdate takes too long to list
if $SOFTWAREUPDATE && ! softwareupdate -l | grep "No new software available"; then
	log_verbose update your Mac with all system changes
	sudo softwareupdate -ia
fi

"$SCRIPT_DIR/install-python.sh"

# aws need this
# aws cli needs python and uses jq to parse output from it in bash scripts
PACKAGES+=" jq "

# rsync-and-hash keeps crashing with old v2.6
PACKAGES+=" rsync "

if $MACPORTS_INSTALL && ! command -v port >/dev/null; then
	log_verbose also install mac ports for compatibility
	"$SCRIPT_DIR/install-macports.sh"
	log_verbose Pick up the new port instructions
	source_profile

	log_verbose "Prefer brew so first uninstall all Macports of $PACKAGES"
	if ! sudo port uninstalled "$PACKAGES"; then
		log_verbose "no Macports $PACKAGES found"
	fi

fi

log_verbose update all package repos
package_update

log_verbose rehash commands updated packages
hash -r
log_verbose "install $PACKAGES"
package_install "${PACKAGES[@]}"

hash -r

# install-gnu.sh returns the path for the gnu utilities
# so you can also export from it
# Needs to run before the config_mark and other commands since
# these use readlink
log_verbose install packages that need special flags
"$SCRIPT_DIR/install-gnu.sh"
log_verbose The path for getting to gnu utilities needed so source the new profile
source_profile
hash -r

log_verbose checking to see if should update .bash_profile
if ! config_mark; then
	# put a guard in so we don't keep adding path variables
	# shellcheck disable=SC2016
	config_add <<<'[[ $PATH =~ /usr/local/bin ]] || export PATH="/usr/local/bin:$PATH"'
fi

log_verbose make sure we have the lastest paths loaded
source_profile
log_assert "! command -v python | grep /usr/bin" "Using Homebrew Python"

log_verbose make sure brew is in the path

# or just do a full source
log_verbose pick up path changes from gnu
source_profile

# https://superuser.com/questions/630911/vi-command-doesnt-open-newly-installed-vim-7-4-on-os-x
# need these options so vi gets used and the override requires python3
# https://stackoverflow.com/questions/24617701/installing-vim-with-homebrew-assistance
# superceeds this, no longer need --with-override-system-vim and the other
# options are not gone as well
# log_verbose install vim compiled with python 2 bindings then remove--with-python2 use --with-python3
#brew_install --with-override-system-vim --with-lua --with-python3 vim
brew_install vim

log_verbose hash -r to use the new packages
hash -r

# install-divvy uses cask_install underneath but fails over to dmg download
# use divvy instead of shiftit for the big screens
# "$SCRIPT_DIR/install-shiftit.sh"
"$SCRIPT_DIR/install-divvy.sh"

log_verbose install complete Mac apps via brew
#
# VLC - video viewer
# google-backup-and-sync - super set of gdrive and also does photo uploads used
# for veracrypt
#
CASKS+=(vlc
	google-backup-and-sync
)

log_verbose "cask install ${CASKS[*]}"

if ! cask_install "${CASKS[@]}"; then
	log_warning "some installs of ${CASKS[*]}failed"
fi

# install flutter and dart and android studio and google cloud
"$SCRIPT_DIR/install-flutter.sh"
exit
"$SCRIPT_DIR/install-gcloud.sh"
"$SCRIPT_DIR/install-terraform.sh"

# XQuartz is the Mac X-server which you need to see ubuntu apps on a mac client
# via ssh -Y _remote_ _graphical_program_
# This is only v1.18 however, so need to use install-xquartz.sh instead
#PACKAGES+=" xorg-server "
# This seems to hang on some machines, need to debug
log_verbose installing xquartz for remoting linux graphical sessions with ssh -Y
"$SCRIPT_DIR/install-xquartz.sh"

# causes loop don't need
# log_verbose get rid of need to cite for gnu parallel
# parallel --bibtex

# For pre-Sierra, there is no ssh-copy-id and we cannot get ssh-copy-id with
# sudo port install open-ssh +ssh-copy-id
# because this replaces the Mac version of ssh-add which uses the
# Mac keychain, so instead use alternative install
# https://github.com/beautifulcode/ssh-copy-id-for-OSX
if ! command -v ssh-copy-id; then
	log_verbose installing ssh-copy-id
	if ! package_install ssh-copy-id; then
		curl -L https://raw.githubusercontent.com/beautifulcode/ssh-copy-id-for-OSX/master/install.sh | sh
	fi
fi

if command -v port >/dev/null 2>&1; then
	log_verbose Fix up for python to make the defaults work
	if port installed python27 | grep -q "python27.*active"; then
		log_verbose "set python and then hash -r to rebuild command cache"
		sudo port select --set python python27
		sudo port select --set python2 python27
		hash -r
	fi
	if port installed pip27 | grep -q "pip27.*active"; then
		sudo port select --set pip pip27
		hash -r
	fi
fi

log_verbose Install Homebrew Bash over the obsolete default bash v3 in OSX
if brew list bash >/dev/null && [[ ! $(command -v bash) =~ ^/usr/local/bin ]]; then
	log_verbose found Homebrew bash so link it to /usr/local
	brew link --overwrite bash
fi
# http://stackoverflow.com/questions/791227/unable-to-update-my-bash-in-mac-by-macports
# https://johndjameson.com/blog/updating-your-shell-with-homebrew/
# This works for both macports bash and homebrew bash, they install into the same place
# The BASH_PATH check no longer works, so always chsh
DESIRED_SHELL_PATH="$(command -v "$DESIRED_SHELL")"
if [[ -e $DESIRED_SHELL_PATH ]]; then
	if ! grep "$DESIRED_SHELL_PATH" /etc/shells; then
		sudo tee -a /etc/shells <<<"$DESIRED_SHELL_PATH" >/dev/null
	fi
	log_warning "checking $SHELL is same a $DESIRED_SHELL_PATH chsh if not"
	if [[ $SHELL != "$DESIRED_SHELL_PATH" ]]; then
		log_warning you only get one login opportunity to change the shell so type carefully.
		log_warning "if you make a mistake just rerun $SCRIPTNAME"
		chsh -s "$DESIRED_SHELL_PATH"
	fi
fi

# log_verbose install oh-my-zsh
# "$SOURCE_DIR/install-zsh.sh"

log_verbose Enable ssh so you can get into this machine
if ! sudo launchctl list | grep -q sshd; then
	sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
	log_warning "sshd enabled, turn off in System Preferences/Sharing/Remote Login if you don't need it"
fi

if $VMWARE; then
	mkdir -p "$DOWNLOADS"
	pushd "$DOWNLOADS" >/dev/null || return
	log_verbose Install VMware Fusion
	if [[ ! -e "/Applications/VMware Fusion.app" ]]; then
		log_verbose first try brew
		if ! cask_install vmware-fusion; then
			log_verbose brew failed, trying dmg download
			download_url_open https://www.vmware.com/go/try-fusion-en "VMware Fusion.dmg"
			# no longer need to copy, it has it's own installed
			# cp -r "/Volumes/VMware Fusion/VMware Fusion.app" /Applications
			# Need to use find because we could end up with multiple /Volumes with " 2"
			# appended so a simple open does not work
			find_in_volume_open_then_detach "VMware Fusion.app" "VMware Fusion"
		fi
	fi
	log_verbose get Ubuntu
	download_url "http://releases.ubuntu.com/$UBUNTU/ubuntu-$UBUNTU-desktop-amd64.iso"
	log_verbose get Debian
	download_url "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-$DEBIAN-amd64-netinst.iso"
	log_message "ISOs available to Fusion in $DOWNLOADS"
	popd >/dev/null || return
fi

# Install kubernetes not used it is now in docker desktop
# "$SCRIPT_DIR/install-kubernetes.sh"
# Needed for docker for kubernetes minikube
# "$SCRIPT_DIR/install-xhyve.sh"

log_verbose bash completion used by kubernetes
"$SCRIPT_DIR/install-bash-completion.sh"
