# POTNANNY-INSTALL
Installation scripts for the Potnanny greenhouse automation system for Raspberry Pi.

See the main [PotNanny](https://github.com/jeffleary00/potnanny) project for more details and documentation.


## Download Raspbian Lite.
At time of this document, Raspbian 'Stretch' is the latest version and is recommended for this install.


## Burn Raspbian Image to MicroSD card.
There are many ways to do this but [Balena Etcher](https://www.balena.io/etcher/) is a free app and very popular. It is one of our favorites.


## Create SSH file.
Once the Raspbian image has been burned to the MicroSD card, create a plain file called "ssh" in the top-level folder of the MicroSD card. This file can, and should, be empty. It simply needs to exist. *It must not have any file-type extension added (.txt, .doc, etc)*.

Mac or Linux users may want to do this from the command line:
```
touch ssh
```


## Edit the config file.
Use a text editor (see notes below for Windows users), and add the following line to the end of the file named "config.txt"
```
dtoverlay=dwc2
```


## Edit the cmdline file.
Use a text editor and add the following entry to the very end of the single line in file called "cmdline.txt"
```
modules-load=dwc2,g_ether
```


## Eject and insert.
Safely eject the MicroSD card from your computer and insert into the Raspberry Pi.


## Connect USB.
Plug USB cable from your computer to the mini/micro USB port marked "USB" on the Pi.
It may take a minute before the Raspberry Pi fully boots, and the SSH service is available.


## Connect via terminal.
Using a terminal emulator app, connect to the Pi with the following ssh command:
```
ssh pi@raspberrypi.local
```
Enter Yes to confirm you want to connect to the host.
Enter password "raspberry"
You're in.


## Configure WiFi Networking.
```
sudo raspi-config
```
Select option 2 "Network Options"

You will need to enter:
 1. The country.
 2. The WiFi SSID name.
 3. The WiFi passphrase

Select FINISHED when completed.
*NOTE: Use the TAB and ARROW keys to move the menu cursor to other parts of the screen.*


## Get the IP address of the Raspberry Pi.
```
ifconfig -a | grep "inet " | grep -v "127.0.0"
```
The output of this command will look something like:
```
inet 192.168.1.3  netmask 255.255.255.0  broadcast 192.168.1.255
```

You need to know the "inet" address (192.168.1.3, in this case), for connecting to the web interface later.


## Install GIT.
```
sudo apt-get -y install git
```


## Clone the Potnanny install project, and run the installer script.
```
git clone https://github.com/jeffleary00/potnanny-install
cd potnanny-install
bash ./install.bash
```


## Begin using your new Potnanny system!
The Potnanny system can now be accessed via web browser at the URL;
```
https://IPADDRESS
```
Where IPADDRESS is the IPv4 inet address of the Raspberry Pi, as captured in steps above.

 - Login username/password = 'potnanny/potnanny'

You should change this account password immediately! Go to the account settings page.


### Notes for Windows Users.
Do not EVER use Microsoft's "Notepad" app to edit the config files. This program will render the files unreadable to the Raspbian OS. You should use an editor that is capable of handling Linux/Unix formatted files.

Text editor options for Windows users:
 - [gEdit](https://wiki.gnome.org/Apps/Gedit)
 - [Notepad ++](https://notepad-plus-plus.org)

Terminal emulator options for Windows users:
 - [MobaXterm](https://mobaxterm.mobatek.net)
 - [Putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/)
