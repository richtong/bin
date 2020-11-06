#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## install ssmtp so we can send mail
## Uses the ops@surround.io account
## to access smtp.gmail.com
##
## @author Rich Tong
## @returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdvw:e:p:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME installs ssmtp for outbound email"
		echo flags: -d debug, -h help, -v verbose
		exit 0
		;;
	d)
		export DEBUG=true
		;;
	v)
		export VERBOSE=true
		;;
	e)
		EMAIL="$OPTARG"
		;;
	p)
		PASSWORD=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

EMAIL=${EMAIL:-"ops@surround.io"}
# App specific password
PASSWORD=${PASSWORD:-"qoodephjylinsyiy"}
SERVER=${SERVER:-"gmail.com"}

set -u
# Get to positional parameters
shift "$((OPTIND - 1))"

if ! command -v ssmtp; then
	sudo apt-get install -y ssmtp
fi

if ! grep -q "Added by $SCRIPTNAME" /etc/ssmtp/ssmtp.conf; then
	sudo tee /etc/ssmtp/ssmtp.conf <<-EOF

		# Added by $SCRIPTNAME on $(date)
		# See http://www.havetheknowhow.com/Configure-the-server/Install-ssmtp.html
		root=$EMAIL
		mailhub=smtp.$SERVER:587
		AuthUser=$EMAIL
		AuthPass=$PASSWORD
		UseTLS=YES
		UseSTARTTLS=YES
		rewriteDomain=$SERVER
		hostname=$EMAIL
		FromLineOverride=YES

	EOF
fi

if ! grep -q "root:$EMAIL" /etc/ssmtp/revaliases; then
	sudo tee -a /etc/ssmtp/revaliases <<-EOF
		root:$EMAIL:smtp.$SERVER:587
	EOF
fi

# note the |& does not work in mac bash so use simpler cousin
if ! sendmail -V 2>&1 | grep -q sSMTP; then
	log_error 1 "$SCRIPTNAME: ssmtp did not install and is not emulating sendmail"
fi

# create an email account for me at least
# https://askubuntu.com/questions/350853/cannot-open-mailbox-var-mail-user-permission-denied-no-mail-for-user
sudo adduser "$USER" mail
# For whatever reason you have to create this file
# http://ubuntuforums.org/showthread.php?t=1500892
# install creates and let's you change owner and modifier at once
sudo install /dev/null -o "$USER" -m 600 "/var/mail/$USER"
