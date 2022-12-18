#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Install Flutter (and DART) for iOS and Android development
## Use standard build environment layout
## Expects there to be aws keys in a key file
## Also installs Google Cloud SDK for use as a backend
## Significnatly simpler now
## https://dev.to/misterf/install-flutter-for-macos-using-homebrew-1de7
##
## older way
## https://gist.github.com/agrcrobles/165ac477a9ee51198f4a870c723cd441
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# get command line options
OPTIND=1
# disable web support
NOWEB="${NOWEB:-false}"
FDIR="${FDIR:-"/usr/local/Caskroom/flutter/latest"}"
while getopts "hdvnf:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: install aws
			flags: -d : debug, -v : verbose, -h :help
			       -n Disable Web applications (default: $NOWEB)
			       -f location of the flutter SDK (default: $FDIR)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	n)
		NOWEB=true
		;;
	f)
		FDIR="$OPTARG"
		;;
	*)
		echo "No -$opt" >&2
		;;
	esac
done

# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND - 1))
source_lib lib-install.sh lib-util.sh lib-config.sh

if in_os linux; then
	log_warning "Linux install not complete"
	exit
fi

# https://github.com/MiderWong/homebrew-flutter/blob/master/README.md
# log_verbose brew installing flutter from MiderWong
# As of Sep flutter no longer needs sepcial tap sometimes, but this fails, so
# keep using with
# note there are several implementations of this that are casks see
# https://github.com/socheatsok78/homebrew-flutter
log_verbose brew tap miderwong/flutter not working
# tap_install MiderWong/flutter
# brew_install flutter
log_verbose brew tap flschweiger/homebrew-flutter, had an error
# tap_install flschweiger/flutter
log_verbose brew tap socheatsok78/flutter using had an error
# tap_install socheatsok78/flutter
log_verbose brew tap probablykasper/tap
tap_install probablykasper/tap
log_verbose "installation uninstall required"
cask_uninstall flutter
log_verbose "install flutter"
if ! cask_install flutter; then
	log_error cask_install flutter failed
fi

log_verbose Defeating MacOS quarantine
idevice_path="$FDIR/flutter/bin/cache/artifacts/libimobiledevice"
for file in idevice_id ideviceinfo idevicesyslog; do
	file_path="$idevice_path/$file"
	log_verbose "looking for $file_path"
	if [[ -e $file_path ]] && ! sudo xattr -d com.apple.quarantine "$file_path"; then
		log_verbose no quarantine set on $file
	fi
done

# dart installed with flutter now
# https://github.com/dart-lang/homebrew-dart
# log_verbose install dart
# brew_install dart

# java required for certain android tools like the keyfinder
# https://stackoverflow.com/questions/24342886/how-to-install-java-8-on-mac#28635465
# java installs latest java currently jave 13
# To install older version
# tap_install adoptopenjdk/openjdk
# cask_install adoptopenjdk8
#
# Also install google cloud so firebase can be used with flutter
log_verbose install android studio and other casks
cask_install \
	android-studio \
	cocoapods \
	java

# this generates an error on Big Sur
log_verbose flutter precache
flutter precache

# https://flutter.dev/docs/get-started/install/macos
log_verbose install Xcode
mas install 497799835
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
# https://apple.stackexchange.com/questions/175069/how-to-accept-xcode-license
sudo xcodebuild -license accept

# These are obsolete, the android-studio install handles it all now
# Intel HAXM - Hardware acceleration for VMs
# Android Studio - Development kit
# Java SDK
# log_warning "Android needs Java v8 not 9"
# https://github.com/Homebrew/homebrew-cask/issues/58883
# The ndk
# android-ndk no longer in homebrew/core, but in /cask
# but is not in the homebrew/cask
#brew tap homebrew/cask
#           android-ndk \
#           android-sdk \
#           intel-haxm \
#           adoptopenjdk8 \
#
flutter doctor --android-licenses

# https://flutter.dev/docs/get-started/web
if ! $NOWEB; then
	log_verbose enabling beta feature web support
	log_warning currently must use Chrome to see web apps
	cask_install google-chrome

	if ! flutter channel beta; then
		log_warning flutter no longer has a beta channel
	fi
	flutter upgrade
	flutter config --enable-web
	flutter devices
	log_warning to add to an existing project run flutter create . in that project dir
	log_warning using flutter run -d chrome and look at http://localhost
fi

# From flutter doctor but these are already installed above
# log_verbose workaround until next release of libimobiledevice 1.1.0
# log_verbose get old version and recompile needs autoconf and automake
# brew_install autoconf automake
# brew_install --HEAD usbmuxd libimobiledevice
# This doesn't seem to be needed
# brew link usbmuxd libimobiledevice

#https://gist.github.com/patrickhammond/4ddbe49a67e5eb1b9c03
# log_warning ant requires adoptopenjdk8 first
# brew_install \
#            ant \
#           maven \
#          gradle \
#           ios-deploy \
#           ideviceinstaller

# Java 9 workaround so don't install java
# export SDKMANAGER_OPTS="-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee"
# caskroom/versions/java8 \

# This update is deprecated
# android update sk --no-ui
# need to touch this before
#mkdir -p "$HOME/.android"
#touch "$HOME/.android/repositories.cfg"
#sdkmanager --update
# note build tools are not installed by default
#sdkmanager "platform-tools" "platforms;android-28" "build-tools;28.0.3"

# All profiles are adding automtically
#if ! config_mark
#then
#  log_verbose adding Android profiles to the $(config_profile)
#  # http://tldp.org/LDP/abs/html/here-docs.html
#  # prevent command line substitution
#  config_add <<-'EOF'
#  export ANDROID_SDK_ROOT="/usr/local/share/android-sdk"
## export PATH=$ANDROID_SDK_ROOT/build-tools/$(ls $ANDROID_SDK_ROOT/build-tools | sort | tail -1):$PATH
#EOF
#fi

flutter doctor
source_profile

log_warning "Make sure to sign up with your Apple Developer account in Xcode"
log_warning "In xCode/Preference/Accounts/ and add a Development certificate"
log_warning "then do a flutter create && flutter run"
log_warning "Add to the project bundler the certificate"
log_warning "Start Android Studio and in Preferences/Plugins to add flutter plugin"
log_warning "When you click on New Flutter Application, the Flutter SDK is at"
log_warning "/usr/local/Caskroom/flutter/latest/flutter"
log_warning "Then go to AVD Manager and create a virtual device"
log_warning "Finally to SDK Manager to create the corresponding SDK"
log_warning "When running a Flutter app, make sure to start the simulator first"
log_warning "then the device emulator will appear"
