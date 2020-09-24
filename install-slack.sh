
##
## install slack
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
VERSION=${VERSION:-2.8.2}
MAC_URL=${MAC_URL:-"https://slack.com/ssb/download-osx"}
while getopts "hdvu:r:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install slack
            echo "flags: -d debug, -h help"
            echo "       -u url for program (default: $MAC_URL for MacOS"
            echo "       -r linux downloads specific version number $VERSION or later"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        u)
            MAC_URL="$OPTARG"
            LINUX_URL="$OPTARG"
            ;;
        r)
            VERSION="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-mac.sh lib-util.sh lib-version-compare.sh

set -u
shift $((OPTIND-1))

if command -v slack
then
    log_exit "Slack installed"
fi

if in_os docker
then
    log_exit no need for slack in docker
fi

if cask_install slack
then
    log_exit "Brew cask installed for Slack"
fi
log_verbose homebrew install failed

if [[ $OSTYPE =~ darwin ]]
then
    log_verbose installing on Mac
    if [[ ! -e /Applications/Slack.app ]]
    then
        # note that the url basename is not meaningful for slack for mac
        download_url_open  "$MAC_URL" "slack.zip" "$DOWNLOAD_DIR"
        sudo rm -rf "/Applications/Slack.app"
        sudo mv "$DOWNLOAD_DIR/Slack.app" /Applications
    fi
    exit
fi


log_verbose installing on linux with apt-get

log_verbose gconf2 not installed by default on debian
log_verbose ubuntu 16.04 not installed libappindicator1 or curl
package_install gconf2 curl
if in_linux ubuntu
then
    package_install libappindicator1 libindicator7
    log_verbose on naked Ubuntu 16.04 Server SMI on amazon need addition
    package_install xdg-utils
fi
log_verbose Debian 9 need gvfs-bin
package_install gvfs-bin

log_verbose attempt to find the latest Linux version number
online=$(curl -Ls https://slack.com/downloads/linux | grep "Version")
log_verbose found version string online $online
# http://tldp.org/LDP/abs/html/x17129.html
if [[ $online =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]
then
    log_verbose found version number $BASH_REMATCH
    if vergte "$BASH_REMATCH" "$VERSION"
    then
        VERSION="$BASH_REMATCH"
    fi
fi
LINUX_URL=${LINUX_URL:-"https://downloads.slack-edge.com/linux_releases/slack-desktop-$VERSION-amd64.deb"}
log_verbose downloading from  $LINUX_URL
deb_install slack-desktop "$LINUX_URL"
