#!/usr/bin/env bash
##
## Configure a sphinx directory
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
export FLAGS="${FLAGS:-""}"
DOCS="${DOC:-"$HOME/ws/git/patents"}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Configure a sphinx system and install a new conf.py
			    usage: $SCRIPTNAME [ flags ] [ sphinx directories ]
			    flags: -d debug, -v verbose, -h help"

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
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND - 1))

if (($# > 0)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	DOCS=("$@")
fi

log_verbose "installing conf.py files in ${DOCS[*]}"
for doc in "${DOCS[@]}"; do
	if [[ ! -d $doc ]]; then
		log_verbose "$doc does not exist skipping"
		continue
	fi
	conf_file="$doc/conf.py"
	if [[ ! -e $conf_file ]]; then
		log_verbose Create the configuration file if it does not already exist
		if ! pushd "$doc" >/dev/null; then
			log_error "no $doc"
		fi
		sphinx-quickstart
		popd >/dev/null || true
	fi

	# Add the author initial replacement text
	if ! config_mark "$conf_file"; then
		config_add "$conf_file" <<EOF
# Added by $SCRIPTNAME by $(date)
extensions += 'sphinx.ext.graphvis'
rst_epilog = """
.. |bw| replace:: Robert Weyland
.. |jc| replace:: John Cordell
.. |jl| replace:: John Ludwig
.. |sm| replace:: Sam Mckelvie
.. |vs| replace:: Vlad Sadovsky
.. |rt| replace:: Richard Tong
"""
# plantuml for protocol diagrams
extensions += 'sphinxcontrib-plantuml'
# this only works for local installs of plantuml
# plantuml = 'java -jar ' + os.path.expand('~') + 'plantuml.jar'
# works for home brew installation directly calling with java
# plantuml = 'java -jar ' + "$(readlink -f "$(command -v plantuml)")".jar'
# uses the home brew linked app
plantuml = 'plantuml'
EOF
	fi
done
