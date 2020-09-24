#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##install 1password for linux
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
ORG_DOMAIN="{$ORG_DOMAIN:=tongfamily.com}"

OPTIND=1
CLOUD_USER=${CLOUD_USER:-"$USER"}
while getopts "hdvw:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: flags: -d debug, -h help
            echo "    -w WS directory"
            echo "    -u user name for self host (default: $CLOUD_USER"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        w)
            WS_DIR="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh

set -u

SSL_CERT=${SSL_CERT:-"$WS_DIR/git/public-keys/ssl/certs"}
GITHUB_SSH_KEY=${GITHUB_SSH_KEY:-"$HOME/.ssh/$USER@$ORG_DOMAIN-github.com.id_ed25519"}
SSL_PRIVATE_KEY=${SSL_PRIVATE_KEY:-"$HOME/.ssh/$USER@$ORG_DOMAIN.key.pem"}

read -p "Enter your Github password: " GIT_PASS
read -p "Enter your Docker password; " DOCKER_PASS
read -p "Enter your SSL Passphrase: " SSL_PASS

"$WS_DIR/git/src/scripts/cloud/create-ec2-server.py" \
    --server-class=srioservice -d \
    --dns-name=$CLOUD_USER-cloud.alpha.surround.io \
    --secret "github-ssh-key=ssh-key[pass:$GITHUB_PASS]:file:$GITHUB_SSH_KEY" \
    --secret "docker-password=data:pass:$DOCKER_PASS" \
    --secret "ssl-key=ssl-key[pass:$SSL_PASS]:file:<YOUR-SSL-PRIVATE-KEY-FILE>" \
    --artifact intermediate-ca-ssl-certs=$SSL_CERT/$CLOUD_USER-cloud.alpha.surround.io/cert-chain.pem \
    --artifact ssl-cert=$SSL_CERT/$CLOUD_USER-cloud.alpha.surround.io/cert.pem \
    --artifact root-ca-ssl-cert=$SSL_CERT/$CLOUD_USER-cloud.alpha.surround.io/root-cert.pem
