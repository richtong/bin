#
# Perform custom installation of latest xrdp from downloaded sources
#


#-Go to your Download folder
echo "Moving to the ~/Download folders..."
echo "-----------------------------------"
cd ~/Downloads

#Download the xrdp latest files
echo "Ready to start the download of xrdp package"
echo "-------------------------------------------"

#wget https://github.com/neutrinolabs/xrdp/archive/master.zip
git clone --recursive --recurse-submodules git@github.com:neutrinolabs/xrdp.git xrdp-master

#Unzip xrdp package

echo "Extracting content of xrdp package..."
echo "-----------------------------------"
#unzip master.zip

#Install prereqs for compilation

echo "Installing prereqs for compiling xrdp..."
echo "----------------------------------------"
sudo apt-get -y install autoconf libtool libpam0g-dev libx11-dev libxfixes-dev libssl-dev libxrandr-dev nasm

#Install the desktop of you choice - I'm Using Mate Desktop

echo "Installing alternate desktop to be used with xrdp... XFCE4 or Mate"
echo "----------------------------------------------------"
sudo apt-get -y update
#sudo apt-get -y install mate-core mate-desktop-environment mate-notification-daemon --force-yes
sudo apt-get -y install xfce4

echo "Desktop Install Done"
#Configure the Xsession file
#echo mate-session> ~/.xsession
echo xfce4-session >~/.xsession

#Install the X11VNC
echo "Installing X11VNC..."
echo "----------------------------------------"

sudo apt-get -y install x11vnc

#Add/Remove Ubuntu xrdp packages (used to create startup service)

echo "Add/Remove xrdp packages..."
echo "---------------------------"

sudo apt-get -y install xrdp
sudo apt-get -y remove xrdp

#Compile and make xrdp

echo "Installing and compiling xrdp..."
echo "--------------------------------"

cd xrdp-master
# needed because libtool not found in Ubuntu 15.04
# Need to use libtoolize

sudo sed -i.bak 's/which libtool/which libtoolize/g' bootstrap

./bootstrap
./configure
make
sudo make install

#Final Post Setup configuration
echo "---------------------------"
echo "Post Setup Configuration..."
echo "---------------------------"

echo "Set Default xVnc-Sesman"
echo "-----------------------"

sudo sed -i.bak '/\[xrdp1\]/i [xrdp0] \nname=Xvnc-Sesman-Griffon \nlib=libvnc.so \nusername=ask \npassword=ask \nip=127.0.0.1 \nport=-1 \ndelay_ms=2000' /etc/xrdp/xrdp.ini

echo "Symbolic links for xrdp"
echo "-----------------------"

sudo mv /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.backup
sudo ln -s /etc/X11/Xsession /etc/xrdp/startwm.sh
sudo mkdir /usr/share/doc/xrdp
sudo cp /etc/xrdp/rsakeys.ini /usr/share/doc/xrdp/rsakeys.ini




## Needed in order to have systemd working properly with xrdp
echo "-----------------------"
echo "Modify xrdp.service "
echo "-----------------------"

#Comment the EnvironmentFile - Ubuntu does not have sysconfig folder
sudo sed -i.bak 's/EnvironmentFile/#EnvironmentFile/g' /lib/systemd/system/xrdp.service

#Replace /sbin/xrdp with /sbin/local/xrdp as this is the correct location
sudo sed -i.bak 's/sbin\/xrdp/local\/sbin\/xrdp/g' /lib/systemd/system/xrdp.service
echo "-----------------------"
echo "Modify xrdp-sesman.service "
echo "-----------------------"

#Comment the EnvironmentFile - Ubuntu does not have sysconfig folder
sudo sed -i.bak 's/EnvironmentFile/#EnvironmentFile/g' /lib/systemd/system/xrdp-sesman.service

#Replace /sbin/xrdp with /sbin/local/xrdp as this is the correct location
sudo sed -i.bak 's/sbin\/xrdp/local\/sbin\/xrdp/g' /lib/systemd/system/xrdp-sesman.service

#Issue systemctl command to reflect change and enable the service
sudo systemctl daemon-reload
sudo systemctl enable xrdp.service


# Set keyboard layout in xrdp sessions
cd /etc/xrdp
test=$(setxkbmap -query | awk -F":" '/layout/ {print $2}')
echo "your current keyboard layout is.." $test
setxkbmap -layout $test
sudo cp /etc/xrdp/km-0409.ini /etc/xrdp/km-0409.ini.bak
sudo xrdp-genkeymap km-0409.ini

## Try configuring multiple users system
sudo sed -i.bak '/set -e/a mate-session' /etc/xrdp/startwm.sh

echo "Restart the Computer"
echo "----------------------------"
sudo shutdown -r now
