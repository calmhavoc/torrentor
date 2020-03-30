#!/bin/sh


# Don't run this as a script, it will install then remove. Need to redo these parts later.
# TODO
# Install openvpn, configure transmission, configure firewall to use only vpn
# Show downloading ovpn file
# add user inputs for network information

# Fix defaults for prettier and more readable terminal
cd ~
cat "set background=dark" >> ~.vimrc
cat << _EOF >> ~/.bashrc
LS_COLORS='rs=0:di=1;35:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:';
export LS_COLORS
PS1='\e[37;1m\u@\e[35m\W\e[0m\$ '
_EOF


# Update apt and install general packages
apt update
apt install curl mediainfo -y

# Install OpenVPN
apt install openvpn



# Install transmission
apt install transmission-daemon -y
# Open transmission to allow connections
# vi /var/lib/transmission-daemon/.config/transmission-daemon/settings.json (set rpc-whitelist to false)
# service transmission-daemon reload



#### REMOVE AND REPLACE MONO DEPENDENCY, NO LONGER NEEDED
# <>ASDFASDFASDFASDFASDFASDFASDASDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
# DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
#
#--------------------------------------------------------------------------------------------------------

# Install mono for radarr and lidarr  < THIS IS DEPRECATED!!!! redo this section
# TODO
# https://www.mono-project.com/download/stable/#download-lin-ubuntu
apt install gnupg ca-certificates -y
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list
apt update
apt install mono-complete


# Filesystem setup
# chown -R heath.heath /opt/
apt install nfs-common -y
# apt install cifs-utils
mkdir /opt/media_share
echo 192.168.1.5:/volume1/Media /opt/media_share/ nfs rw,auto 0 0 >> /etc/fstab
mount /opt/media_share

####################################################
# Create group account
groupadd media
####################################################



####################################################
# Install Jackett
####################################################
useradd jackett
mkhomedir_helper jackett
usermod -a -G media jackett

cd /opt
curl -L -O $( curl -s https://api.github.com/repos/Jackett/Jackett/releases |grep Jackett.Binaries.LinuxARM32 |grep browser_download_url|head -1 | cut -d \" -f 4 )
tar -xzf Jackett.Binaries.LinuxARM32.tar.gz

chown -R jackett:media /opt/Jackett/
/opt/Jackett/install_service_systemd.sh


####################################################
# Install Radarr 
####################################################
# https://github.com/Radarr/Radarr/wiki/Installation#manually-install-radarr
useradd radarr
mkhomedir_helper radarr
usermod -a -G media radarr


cd /opt
curl -L -O $( curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4 )
tar -xzf Radarr.develop.*.linux.tar.gz



cat << _EOF > /etc/systemd/system/radarr.service
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
# Change the user and group variables here.
User=radarr
Group=media

Type=simple

# Change the path to Radarr or mono here if it is in a different location for you.
ExecStart=/usr/bin/mono --debug /opt/Radarr/Radarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) Radarr from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=/opt/Radarr /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
_EOF

chown -R radarr:media /opt/Radarr/


systemctl enable radarr.service
systemctl start radarr.service


####################################################
# Install SickChill
####################################################

useradd sickchill
mkhomedir_helper sickchill
usermod -a -G media sickchill

# Install dependencies for SickChill
apt-get install python2.7 python-pip python-dev git libssl-dev libxslt1-dev libxslt1.1 libxml2-dev libxml2 libssl-dev libffi-dev build-essential -y
#apt install python-openssl

cd /opt
git clone https://github.com/SickChill/SickChill.git 

cat << _EOF > /etc/systemd/system/sickchill.service
[Unit]
Description=SickChill Daemon
After=syslog.target network.target

[Service]
# Change the user and group variables here.
User=sickchill
Group=media

Type=simple

# Change the path to Radarr or mono here if it is in a different location for you.
ExecStart=/usr/bin/python2.7 /opt/SickChill/SickBeard.py --quiet --config /home/sickchill/config.ini --datadir /home/sickchill/config
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) sickchill from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=/opt/SickChill /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
_EOF

chown -R sickchill:media /opt/SickChill/


systemctl enable sickchill.service
systemctl start sickchill.service

####################################################
# Insstall Lidarr
####################################################
useradd lidarr
mkhomedir_helper lidarr
usermod -a -G media lidarr

cd /opt
curl -L -O $( curl -s https://api.github.com/repos/Lidarr/Lidarr/releases |grep -i linux |grep browser_download_url|head -1 | cut -d \" -f 4 )
tar -xzf Lidarr.master.*.tar.gz

cat << _EOF > /etc/systemd/system/lidarr.service
[Unit]
Description=Lidarr Daemon
After=network.target

[Service]
User=lidarr
Group=media
Type=simple
ExecStart=/usr/bin/mono /opt/Lidarr/Lidarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
_EOF

chown -R lidarr:media /opt/Lidarr/
chmod -R a=,a+X,u+rw,g+r /opt/Lidarr

systemctl enable lidarr.service
systemctl start lidarr.service

# Other stuff
# Install unrar if desired
cd /tmp/
wget http://sourceforge.net/projects/bananapi/files/unrar_5.2.6-1_armhf.deb
dpkg -i unrar_5.2.6-1_armhf.deb


# # if normal unrar install doesn't work, compile from source
# apt-get install build-essential -y
# wget http://rarlab.com/rar/unrarsrc-5.2.6.tar.gz
# tar -xvf unrarsrc-5.2.6.tar.gz
# cd unrar
# make -f makefile
# install -v -m755 unrar /usr/bin

####################################################
# Configure Firewall (ufw)
# set up firewall to allow internal network and only external through tun0
####################################################

apt install ufw
echo "y" | ufw reset
ufw default deny outgoing
ufw allow out on tun0 from any to any
ufw allow from any to port 22
ufw allow from 192.168.1.0/24
ufw allow out on eth0 from any to 192.168.1.0/24
echo "y" |ufw enable

# reset to default
echo "y" | ufw reset
ufw default allow outgoing
echo "y" |ufw enable



# Disable and remove most things
systemctl disable sickchill
systemctl disable lidarr
systemctl disable jackett
systemctl disable radarr

rm /etc/systemd/system/lidarr.service
rm /etc/systemd/system/radarr.service
rm /etc/systemd/system/jackett.service
rm /etc/systemd/system/sickchill.service

rm -rf Jackett* Lidarr* Radarr* SickChill*
rm -rf /home/{lidarr,jackett,radarr,sickchill}
