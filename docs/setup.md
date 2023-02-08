# Security and keys

This is the hardest part of getting things right. Most of this is not necessary
if you use 1Password and enable their ssh-agent.

## SSH key setup

1. First, create a `public-keys/ssh/$USER/` directory and put into it
   your public and encrypted keys to access github.
1. When you are making your keys, you probably want to use the new features in
   OpenSSH 6.5 and in particular use the `-o` flag which bcrypt rather than the
weak MD5 encryption that is the default. Also set the rounds up from the default
16 to something more like `-a 300` which should take a few seconds on a fast
computer and make it hard to brute force your ssh keys. The script prebuild-keys.sh
does this for you.

1. To keep track of your keys, @rich's scripts use this syntax for keys, *user
   email*-*web url for the site you want to login to*.*type of key*. We use this
   instead of the generic id_rsa you see in examples so you can repudiate services
   individually and so that one key loss doesn't mean access to everything you
   have.
1. The unencrypted AWS credentials are kept in the .Private and Private.dmg (for
   Linux and Mac respectively

## Continue the installation if this is a general surround machines

When prebuild is complete you should be able to configure the system, so here
are the rest of the steps if this is *not* a personal machined

1. Once install is complete you have your local environment. Now run
   `src/infra/bin/install-users.sh` and this will create all the other
   developers and agents for surround.
1. At this point any developer should be able to ssh into the machine and agents
   are ready to run.

## Configure a deployment machine or a testing machine

With this done, you can now decide if you also want the various automated systems
to run as well here. What they are:

### Installing agents

This agent runs in its own account and is designed to run 'wscons pre'
continuously and report back via email as to what has happened.

1. Copy the ssh keys needed for agents with ~/prebuild/ssh/{build,test,deploy}
   run from your context.
1. Run prebuild.sh with the -c to create a deployment machine or the -t for a
   testing machine running unit and system test.
1. If you decide to do later, then you need to run
   personal/rich/bin/install-accounts.sh to get all the accounts
1. Then for each separate agent, go to their context and run
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
1. Download the SD and then mount it, then config-hypriot.sh will customize the
   /boot/config.txt so that it will overclock our model B and turn on the
   cameras.
1. Run install-hypriot.sh which will download the SD images, then put them onto
   a SD for each pi. As of now, you have to name each Pi so that is a pain. Each
   is distinct
1. When this is up, then you can run hypriot-camera.sh to take photos. The
   default is ~/ws/runtime/rpi
