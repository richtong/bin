# Installation

Installation and configuration depend on a few key variables like WS_DIR and
having a bootstrap that depends on the environment variables.

## WS_DIR and directory layout

The key shell variable is WS_DIR which is set by [include.sh](include.sh) this
does a search for the directories the parents of a directory close to the
script with a directory `git` in it. So if there are multiple workspace
directories you can end up with errors, it will search alphabetically, so
naming is important, by convention, put your primary workspace in `~/ws` and
then if you have other projects add a letter, so ~/ws is always your first
parent with a `~/ws/git` in it.

The same applies inside your workspace, the `lib_source` function loads in
shell libraries, it searches up and down git looking for a `lib` directory. If
you have for instance cloned ~/ws/git/lib but also have a ~/ws/git/src/lib, it
will pick the first as the library, so when you are working these submodules,
use then in the ~/ws/src.

Also if you have more than one ~/ws, be aware that the way search works, you
~/wsr/src/lib for instance is "shadowed" and will not be seen as a library.

## Preinstall on naked or bare metal installation

For a non-networked machine, To do a bare metal build, create-preinstall.sh which
will give you enough of
this system to put onto a USB key and then bootstrap from there.

Normally you should just clone an entire src repo which will have a bin and lib
submodules. The preinstall will take a Mac convert it with enough git and bash
to run.

To have everything ready, it assumes you have a Veracrypt installation with
your passwords on it in *your username*.vc which lives on your Google Drive.
It will link your keys from there into ~/.ssh which is nice

It also assumes you have a src/user/*your name*/dotfiles directory and will
link your profile and other configurations there.

If you have a network, then you should do:

```sh
# install brew with the one line ruby code that is on their site
git clone --recurse https://github.com/richtong/src
cd src/bin
./preinstall.sh -v
./install.sh -v

```

## Installation Details

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

## AWS Install.sh (deprecated)

This is @rich's poor attempt to automate things. But if you just want to do a
basic installation, here are the steps:

1. Get your AWS accounts and add your public keys to the iam console
1. Get a new machine and create and login, you want to create an administrative
   account to do this, follow the AWS standard and use the account name
   `ubuntu` from there you want to get the iam key service started

   ```bash
   curl -s http://download.xevo-dev.net/bootstrap/install-iam-key-daemon.sh \
      | bash -s
   ```

1. Now you need to hand edit your `/etc/opt/xevo/iam-key.conf.yml` at a minimum
   add yourself as a user at the maximum uncomment docker, sudo, sudonopass
1. Now logout and ssh in as your actual user identity. Leave the ubuntu on as a
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
1. Run `install.sh`
