#!/usr/bin/env bash
##
## install R and RStudio the development environment
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
DESKTOP_RELEASE=${DESKTOP_RELEASE:-0.99.903}
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install R-studio"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -r release of rstudio desktop (default: $DESKTOP_RELEASE)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	r)
		DESKTOP_RELEASE="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

set -u
shift $((OPTIND - 1))
source_lib lib-mac.sh lib-install.sh

if in_os mac; then
	if [[ ! -e /Applications/RStudio.app ]]; then
		# http://tristanpenman.com/blog/posts/2015/10/20/installing-r-and-rstudio-on-mac-os-x/
		log_verbose install R with Brew
		cask_install xquartz
		# https://github.com/Homebrew/homebrew-science/issues/6365
		# is deprecated and R is in the core now
		# brew tap homebrew/science
		brew_install --with-x11 r
		# http://macappstore.org/rstudio/
		log_verbose using Brew to install RStudio
		cask_install rstudio
	fi
	if [[ ! -e /Applications/RStudio.app ]]; then
		# deprecated this is the non-brew installation
		log_verbose Mac installation using packages and downloads
		log_verbose installing R
		package_install r
		log_verbose installing RStudio for the Mac
		download_url_open "https://download1.rstudio.org/RStudio-$DESKTOP_RELEASE.dmg"
	fi
	exit
fi

# https://launchpad.net/~marutter/+archive/ubuntu/rrutter
# log_verbose installing R-base
# sudo add-apt-repository -y ppa:mrutter/rrutter

# http://www.thertrader.com/2014/09/22/installing-rrstudio-on-ubuntu-14-04/
log_verbose installing rstudio server and r-base
sudo add-apt-repository -y ppa:opencpu/rstudio

log_verbose installing cran2deb4ubuntu R packages
sudo add-apt-repository -y ppa:marutter/c2d4u

sudo apt-get update -y

package_install rstudio-server

log_verbose install rstudio desktop
# No longer used but kept for archival purposes
distribution=$(linux_distribution)
if [[ ! $distribution =~ ubuntu ]]; then
	log_warning "only installs on ubuntu for now"
	exit
fi

# https://cran.r-project.org/bin/linux/ubuntu/README
release=$(lsb_release -r | cut -f 2)
if [[ $release =~ 12. ]]; then
	release_name="precise"
elif [[ $release =~ 14. ]]; then
	release_name="trusty"
elif [[ $release =~ 15. ]]; then
	release_name="wily"
elif [[ $release =~ 16. ]]; then
	release_name="xenial"
else
	log_error "cannot install on $release"
fi

log_verbose installing keys
# in original R-studio guide
# gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
# gpg -a --export E084DAB9 | sudo apt-key add .
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com E084DAB9

log_verbose adding $release_name repo
# note there is a space in the repo name between distribution and release
repo="deb http://cran.rstudio.com/bin/linux/$distribution $release_name/"
if ! grep -q "^$repo" /etc/apt/sources.list; then
	# http://askubuntu.com/questions/197564/how-do-i-add-a-line-to-my-etc-apt-sources-list
	sudo add-apt-repository "$repo"
fi

log_verbose install R
sudo apt-get update -y

sudo apt-get install -y r-base

# https://www.rstudio.com/products/rstudio/download/
log_verbose installing rstudio from debian package
url="https://download1.rstudio.org/rstudio-$DESKTOP_RELEASE-amd64.deb"
md5="98ea59d3db00e0083d3e4053514f764d"
deb_install rstudio "$url" "$(basename "$url")" "$WS_DIR/cache" "$md5"
