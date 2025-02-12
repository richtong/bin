#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
## The above gets the latest bash on Mac or Ubuntu
##
##install sphinx for Mac
##
## This has been tested on Mac and installs our patent system
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

EXTENSIONS="${EXTENSIONS:-"googlechart googlemaps plantuml exceltable httpdomain"}"

OPTIND=1
while getopts "hdve:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs sphinx the document generation tool and associated products

			Usage  $SCRIPTNAME [flags...]

			flags: -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
			       -e extensions
			          (default: $EXTENSIONS)

			To use these extensions add to your conf.py. Note that if the files are named
			different from their extension names, in the conf.py use a dot

			For example, we pip install using a dash to separate:

		EOF
		for ext in $EXTENSIONS; do
			echo "pip install sphinxcontrib-$ext"
		done

		printf "\nBut in conf.py set extensions using a dot to separate\n"
		for ext in $EXTENSIONS; do
			echo "extensions.append('sphinxcontrib.$ext)"
		done

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
	e)
		EXTENSIONS="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-config.sh

# http://mbless.de/blog/2015/01/26/sphinx-doc-installation-steps.html
# https://pypi.python.org/pypi/sphinxcontrib-googlechart
# googlechart - pie charts and graphs
# .. piechart ::
#    us: 50
#    them:40
#    other: 10
# https://pypi.python.org/pypi/sphinxcontrib-googlemaps
# .. googlemaps:: Shibuya Station
#
# t3SpinxThemeRtd - beautiful theme use in conf.py
#  import t3SphinxThemeRtd
#  html_theme="t3SphinxThemeRtd"
#  htmo_theme_path = [t3SpinxThemeRtd.get_html_themepath() ]
#
# Documents rest apis
# https://pythonhosted.org/sphinxcontrib-httpdomain/
# add to conf.py
# extensions = [ 'asphinxcontrib-httpdomain' ]
# .. http:get:: /users/(int:user_id)/posts/(tag)
#    Post are tagged with `tag` from user `user_id`
#    .. sourcecode:: http
#       GET /users/123/posts/web HTTP1.1
#       Host: example.com
#
# Plantuml - for flow diagrams
#
# Exceltable - embed excel spreadsheet
# https://bitbucket.org/birkenfeld/sphinx-contrib/
# has all the sphinx modules in a git repo, but easier to let pip maintain the
# versions
log_verbose "pip install sphinx-doc globally"
# pip_install --user --upgrade sphinx
pipx_install sphinx-doc
# https://scicomp.stackexchange.com/questions/2987/what-is-the-simplest-way-to-do-a-user-local-install-of-a-python-package
log_verbose "install extensions $EXTENSIONS"
for ext in $EXTENSIONS; do
	# if you want to be only local
	# pip install --user "$USER" sphinx-contrib-$ext
	log_verbose "install extension $ext globally"
	# pip_install --user --upgrade "sphinxcontrib-$ext"
	pipx_install "sphinxcontrib-$ext"
done

log_verbose install graphviz
package_install graphviz

log_verbose install plantuml
if ! package_install plantuml; then
	log_debug create plantuml for protocol diagrams
	my_bin="/usr/local/bin"
	mkdir -p "$my_bin"
	plantuml="$my_bin/plantuml.jar"
	if [[ ! -e $plantuml ]]; then
		curl -L http://sourceforge.net/projects/plantuml/files/plantuml.jar/download -o "$plantuml"
	fi
fi

log_verbose install tex
if [[ $OSTYPE =~ darwin ]]; then
	log_verbose "install basictex the small version of mactex"
	package_install basictex
	# should never need this but leave just in case
	# log_verbose checking for py27-sphinx
	# if port installed py27-sphinx | grep "not installed"
	# then
	#     sudo port select --set sphinx py27-sphinx
	# fi
else
	log_verbose installing texlive
	package_install texlive
fi
