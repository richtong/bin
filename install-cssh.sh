#!/usr/bin/env bash
##
## Installs clusterssh on Linux or Mac
##
## Installs configuration files as well in ~/.csshrc
## https://www.linux.com/learn/managing-multiple-linux-servers-clusterssh#
##
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install cluster ssh"
		echo "flags: -d debug, -h help -v verbose"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-config.sh lib-util.sh

log_verbose check for installation
if in_os mac; then
	log_verbose "in mac install csshX"
	package_install csshx
	if ! config_mark "$(config_profile_nonexportable)"; then
		log_verbose adding cssh alias
		config_add "$(config_profile_nonexportable)" <<-EOF
			if command -v csshx >/dev/null; then alias cssh=csshX; fi
		EOF
	fi
else
	log_verbose "package install clusterssh"
	package_install clusterssh
fi

# generate car sensors to stdout
# usage: name flavors_in_bash_sequence variants_in_bash_sequence_syntax
# example: name_generate ai {0..3} {,r,.local}
# This does not work with bash 4.4 as of August 2017 the parser
# does not handle a bash sequence inside a conditional variable
# and does not correctly pass bash sequences through parameter substitution
# not used use brace expansion instead
name_generate() {
	local name="${1:-car}"
	# Note that if you add quote to the iterator this breaks
	local flavors="${2:-{0..3}}"
	# bash parser in 4.4 does not know how to deal with the below
	# it shioukd result in front.local, back.local, outside1.local...
	# but insteads does front b ack outside1.local because local binds
	# only to the inner bash sequence expansion
	local variants="${3:-{front,back,driver,outside{1..5}}.local}"

	# need an eval here to for the iterator to use the variable
	# and do math on total
	# use brace expansions http://wiki.bash-hackers.org/syntax/expansion/brace
	log_verbose "generate names with name=$name and flavors=$flavors and variants=$variants"
	log_verbose "running eval echo $name$flavors"
	eval echo "$name$flavors"
	for item in $(eval echo "${name}${flavors}"); do
		log_verbose "starting $item"
		eval echo "${item}{,${variants}}"
	done
}

# https://www.linux.com/learn/managing-multiple-linux-servers-clusterssh
# http://manpages.ubuntu.com/manpages/xenial/man1/cssh.1p.html
config="$HOME/.clusterssh/config"
if in_os mac; then
	config="$HOME/.csshrc"
fi
log_verbose checking for config
outsides=6
# the bash eval cannot have any spaces between the commas
# https://www.gnu.org/software/bash/manual/html_node/Brace-Expansion.html
# heavy use of brace expansion
#outside="$(eval echo "outside{1..$outsides}" | tr " " ",")"
cars=4
if ! config_mark "$config"; then

	eval echo "all car{0..$((cars - 1))} ai{,r,.local}" | config_add "$config"
	# name_generate car '"{0..3}"' '"{front,back}"'
	# name_generate | config_add "$HOME/.clusterssh/config"

	# need the eval echo to allow bash variables in the iterator
	for car in $(eval echo "car{0..$((cars - 1))}"); do
		log_verbose "adding $car"
		log_verbose evaluates to "$(eval echo "$car $car{front,back,driver,outside{1..$outsides}}.local")"
		# note how the local applies to the suffixes and a null item means add
		# no string need parens around the items
		# would need an eval if a bash variable was part of an iterator
		# also we need ${car} to make sure the next iterator is parsed correctly
		#eval echo "${car}{" = ",{front,back,driver,outside{1..$outsides}}.local}" | config_add "$config"
		# nested brace expansion
		eval echo "$car $car{front,back,driver,outside{1..$outsides}}.local" | config_add "$config"
	done

	log_verbose adding ai? and ai?r for remote
	for site in "" r .local; do
		# do not need eval
		eval echo "ai$site ai{0..4}$site" | config_add "$config"
	done
	# the above use of bash expansion replaced these lines
	#config_add "$HOME/.clusterssh/config" <<-EOF
	#all  cars0 car1 car2 car3
	#car0 car0front.local car0back.local car0driver.local car0outside1.local car0outside2.local car0outside3.local car0outside4.local car0outside5.local
	#car1 car1front.local car1back.local car1driver.local car1outside1.local car1outside2.local car1outside3.local car1outside4.local car1outside5.local
	#car2  car2front.local car2back.local car2driver.local car2outside2.local car2outside2.local car2outside3.local car2outside4.local car2outside5.local
	#car3  car3front.local car3back.local car3driver.local car3outside3.local car3outside3.local car3outside3.local car3outside4.local car3outside5.local
	#EOF
fi
