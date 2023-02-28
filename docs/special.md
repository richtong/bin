# Special

Here are some special things you can do to create a ZFS server or a Raspberry
Pi setup.

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
