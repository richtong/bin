# Infrastructure commands

These are (mainly by @richtong) convenience programs for use in installing and
managing the dev environment. They are mainly experimental and are called from here.
There are a few which are used and these are connected to local-bin. See
local-bin/README.md for how to do that

Most of time if you need to install something just try grepping

## Installation

This assumes that there is a next door directory `../lib` which has library
functions. Normally, this is a submodule based on @richtong's library.

You normally put both into a `rt/{bin, lib}` directories in your project. Or if
you are not going to be using any other bins, then put directly into /bin or
/lib of the repo

If you are contributing code then run `make pre-commit` and use shellcheck to
make sure you are writing good shell scripts. It is also a good idea to add
this directory to your path in `.bash_profile`

So the installation works like:

```shell
cd ~/ws/git/src  # or where your repo is
git submodule add git@github.com:richtong/bin
cd bin
make repo-init
```

## Global variables

These are kept in [../lib/include.sh] and you should change ORG_NAME to reflect
where you have forked things

## Install.sh

This is @rich's poor attempt to automate things. But if you just want to do a
basic installation, here are the steps:

1. Get your AWS accounts and add your public keys to the iam console
2. Get a new machine and create and login, you want to create an administrative
   account to do this, follow the AWS standard and use the account name
   `ubuntu` from there you want to get the iam key service started

```bash
curl -s http://download.xevo-dev.net/bootstrap/install-iam-key-daemon.sh | bash -s

3. Now you need to hand edit your `/etc/opt/xevo/iam-key.conf.yml` at a minimum
   add yourself as a user at the maximum uncomment docker, sudo, sudonopass

4. Now logout and ssh in as your actual user identity. Leave the ubuntu on as a
   backdoor in case you need to configure

```bash
sudo apt-get install git
mkdir -p ws/git
cd ws/git
git clone https://github.com/surround-io/src
cd src/infra/bin
```

1. Now you can run install to make sure the defaults are OK run `install.sh -h`
   and you can see how it will configure override with the appropriate flag. It
   tries to guess your user name and your docker name but often guesses wrong
   particularly with docker.

```bash
~/ws/git/src/infra/bin/install.sh -r _your dockeR name_
```

1. Note that install.sh works on Debian 9, Ubuntu 14.04, ubuntu 16.0. It also
   runs inside VMware fusion

## Configuring your Mac

Note that `install.sh` also works to configure your Mac as a development
machine, so here are the steps:

1. Git clone on your mac to `mkdir -p ws/git; cd ws/git; git clone surround-`
2. Run `install.sh`

## Note on the programs

The rest of the programs are various scripts that are helpers after you create
things. Rich is constantly adding to them. They use a common `include.sh` which
loads libraries and finds $WS_DIR.

Since these are mainly experimental the vast majority a simple shell scripts.
The ones that need it are rewritten as python such as the docker files that @sam
did.

These scripts have a couple of nice common features:

- They single step with -d flag. This flag is exported with $DEBUGGING so you
  just say -d once and all scripts called honor it.
- The same with the -v verbose flag.
- Libraries for these are kept in ../lib and are common shell functions. For
  instance the debug behavior is in ../lib/lib-debug.sh
- They find the current WS_DIR automatically. They look up from their execution
  directory for ws and if they can't find it, they look down from your $HOME.

Works most of time. If it doesn't, use export WS_DIR ahead of the script call.
Or use wbash or wrun

## Agent scripts vs dev scripts

Some of these scripts are for use by agents. They are different mainly because
agents for local build do not have sudo rights.

## Helper role of ../etc and ../lib

The ../etc files are text configuration files:

users.txt: This is a list of user names, uid and gids
groups.txt: common groups used on common machines
hostnames.txt: hostnames already in use
wordlist.txt: a list of hostnames not allocated for use by new machines

## List of files and what they do

create-keys.sh - Creates ssh keys securely using latest on disk encryption
docker-machine-create.sh - So you can have a docker machine swarm
git-reset.sh - When you just want everything reset to master
install-1password.sh - Installs Linux 1-password
install-accounts.sh - Used by prebuild, this populates your local machine with
all user accounts
install-agent.sh - Run by a local agent to create crontab etc
install-agents.sh - Creates all agent currently test, build and deploy
install-apache.sh - Installs apache
install-aws-config.sh - Installs your personal config of aws from your secret
keys
install-aws.sh - Installs aws command line
install-caffe.sh - Not complete, but this installs caffe
install-crontab.sh - Installs entries into crontab used by agents
install-dwa182.sh - For the D-link Wifi USB adapter (AC1200!)
install-flocker.sh - not complete, this is docker for data volumes
install-hostname.sh - Gives you a new hostname from wordlist.txt
install-lfs.sh - Installs lfs for you
install-mail.sh - Used by agents, verifies that ssmtp is installed
install-modular-boost.sh - Not used but testing for modular boost standalone
install-neon.sh - Not complete for Neon machine learning
install-nvidia.sh - Installs nvidia proprietary drivers
install-pia.sh - Installs Private Internet access VPN
install-ruby.sh - Not sued, installs ruby
install-spotify.sh - Installs spotify for Linux, not debugged
install-sshd.py - Installs the ssh daemon so you can ssh into your machine
install-ssmtp.sh - Installs a simple mail transport send through ops@surround.io
install-sublime.sh - Installs sublime, not debugged
install-travis-env.sh - Installs the travis routines for 12.04, deprecated,
install-travis.sh - Installs travis, not debugged
install-vim.py - Vim lint checkers for sh, python, Javascript
install-vim.sh - deprecated, and as first version of python script
install-vmware-tools.sh - Checks for latest vmware tools
install-vpn.sh - Installs a vpn file
make-bin.sh - Converts one of these files into a general use with src/bin
make-password.sh - Creates a secure password
remove-accounts.sh - Cleans up a machine removing all create by install-users.sh
remove-agents.sh - Cleans up install-agents.sh
remove-all.sh - Cleans everything that accounts and agents does
remove-crontab.sh - Removes all crontab entries
remove-prebuild.sh - Removes all the files create
start-vpn.sh - starts a vpn to surround.io
system-run.sh - used by agents, runs wscons and starts alpha 2
system-test.sh - Not debugged yet, but runs system wide tests for alpha 2
verify-docker.sh - Ensures we have the rights to run docker

## SSH key setup

1. First, create a public-keys/ssh/$USER/ directory and put into it
   your public and encrypted keys to access github.
2. When you are making your keys, you probably want to use the new features in
   OpenSSH 6.5 and in particular use the `-o` flag which bcrypt rather than the
weak MD5 encryption that is the default. Also set the rounds up from the default
16 to something more like `-a 300` which should take a few seconds on a fast
computer and make it hard to brute force your ssh keys. The script prebuild-keys.sh
does this for you.
3. To keep track of your keys, @rich's scripts use this syntax for keys, _user
   email_-_web url for the site you want to login to_._type of key_. We use this
instead of the generic id_rsa you see in examples so you can repudiate services
individually and so that one key loss doesn't mean access to everything you
have.
4. The unencrypted AWS credentials are kept in the .Private and Private.dmg (for
   Linux and Mac respectively

## Continue the installation if this is a general surround machines

When prebuild is complete you should be able to configure the system, so here
are the rest of the steps if this is *not* a personal machined

1. Once install is complete you have your local environment. Now run
   `src/infra/bin/install-users.sh` and this will create all the other
   developers and agents for surround.
2. At this point any developer should be able to ssh into the machine and agents
   are ready to run.

## Configure a deployment machine or a testing machine

With this done, you can now decide if you also want the various automated systems
to run as well here. What they are:

### Installing agents

This agent runs in its own account and is designed to run 'wscons pre'
continuously and report back via email as to what has happened.

1. Copy the ssh keys needed for agents with ~/prebuild/ssh/{build,test,deploy}
   run from your context.
2. Run prebuild.sh with the -c to create a deployment machine or the -t for a
   testing machine running unit and system test.
3. If you decide to do later, then you need to run
   personal/rich/bin/install-accounts.sh to get all the accounts
4. Then for each separate agent, go to their context and run
   personal/rich/bin/install-agents.sh

### Function so each agent

Here are the functions:

- build. This just runs Scons pre continuously as a clean build.
- test. This runs the automated system test. Configuring cameras and running
  against a test to make sure that the web server and the camera feeds work. It
then takes them down
- deploy. This runs the app-host and web server so things are ready for service

## Creating a file server

First create a special admin account typically called 'surround' and then you
will create the surround.io standard accounts and then install ZFS

```shell
mkdir -p ~/ws/git
cd ~/ws/git
git clone https://github.com/surround-io/src
cd ~/ws/src/infra/bin
./install-accounts.sh
```

Now you want to see what you have

## Using the Raspberry Pi as a dockerized camera system

This is @rich's side project. Here is what you need to do:

1. Get a set of Raspberry Pi's with their cameras installed. We have lots so
   just ask Rich for a set we have literally a hundred of them.
2. Download the SD and then mount it, then config-hypriot.sh will customize the
   /boot/config.txt so that it will overclock our model B and turn on the
cameras.
3. Run install-hypriot.sh which will download the SD images, then put them onto
   a SD for each pi. As of now, you have to name each Pi so that is a pain. Each
   is distinct
4. When this is up, then you can run hypriot-camera.sh to take photos. The
   default is ~/ws/runtime/rpi
