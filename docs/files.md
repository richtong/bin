# List of files and what they do

This is not a complete list as it is manually generated. The next step is to
use a shell extract to get it.

- create-keys.sh - Creates ssh keys securely using latest on disk encryption
- docker-machine-create.sh - So you can have a docker machine swarm
- git-reset.sh - When you just want everything reset to master
- install-1password.sh - Installs Linux 1-password
- install-accounts.sh - Used by prebuild, this populates your local machine with
- all user accounts
- install-agent.sh - Run by a local agent to create crontab etc
- install-agents.sh - Creates all agent currently test, build and deploy
- install-apache.sh - Installs apache
- install-aws-config.sh - Installs your personal config of aws from your secret
- keys
- install-aws.sh - Installs aws command line
- install-caffe.sh - Not complete, but this installs caffe
- install-crontab.sh - Installs entries into crontab used by agents
- install-dwa182.sh - For the D-link Wifi USB adapter (AC1200!)
- install-flocker.sh - not complete, this is docker for data volumes
- install-hostname.sh - Gives you a new hostname from wordlist.txt
- install-lfs.sh - Installs lfs for you
- install-mail.sh - Used by agents, verifies that ssmtp is installed
- install-modular-boost.sh - Not used but testing for modular boost standalone
- install-neon.sh - Not complete for Neon machine learning
- install-nvidia.sh - Installs nvidia proprietary drivers
- install-pia.sh - Installs Private Internet access VPN
- install-ruby.sh - Not sued, installs ruby
- install-spotify.sh - Installs spotify for Linux, not debugged
- install-sshd.py - Installs the ssh daemon so you can ssh into your machine
- install-ssmtp.sh - Installs a simple mail transport send through ops@surround.io
- install-sublime.sh - Installs sublime, not debugged
- install-travis-env.sh - Installs the travis routines for 12.04, deprecated,
- install-travis.sh - Installs travis, not debugged
- install-vim.py - deprecated Vim lint checkers for sh, python, Javascript
- install-vim.sh - installs vim
- install-vmware-tools.sh - Checks for latest vmware tools
- install-vpn.sh - Installs a vpn file
- make-bin.sh - Converts one of these files into a general use with src/bin
- make-password.sh - Creates a secure password
- remove-accounts.sh - Cleans up a machine removing all create by install-users.sh
- remove-agents.sh - Cleans up install-agents.sh
- remove-all.sh - Cleans everything that accounts and agents does
- remove-crontab.sh - Removes all crontab entries
- remove-prebuild.sh - Removes all the files create
- start-vpn.sh - starts a vpn to surround.io
- system-run.sh - used by agents, runs wscons and starts alpha 2
- system-test.sh - Not debugged yet, but runs system wide tests for alpha 2
- verify-docker.sh - Ensures we have the rights to run docker
