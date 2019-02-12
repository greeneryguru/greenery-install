#!/bin/bash

# -----------------------------------------------------------------------------
#
# Run this as the 'pi' user (or other superuser) on Raspberry Pi
#
# -----------------------------------------------------------------------------


echo "INSTALL LIBRARIES AND APPLICATIONS"
echo "---------------------------------------------------------"
sudo apt-get update
sudo apt-get -y install build-essential
sudo apt-get -y install libglib2.0-dev
sudo apt-get -y install libbluetooth-dev
sudo apt-get -y install git
sudo apt-get -y install python3-dev
sudo apt-get -y install python3-cryptography
sudo apt-get -y install python3-pip
sudo apt-get -y install nginx
sudo apt-get -y install uwsgi
sudo apt-get -y install uwsgi-plugin-python3
sudo apt-get -y install sqlite


echo "INSTALL PYTHON MODULES"
echo "---------------------------------------------------------"
sudo pip3 install sqlalchemy
sudo pip3 install marshmallow
sudo pip3 install flask
sudo pip3 install flask-restful
sudo pip3 install flask-jwt-extended
sudo pip3 install bluepy
sudo pip3 install btlewrap
sudo pip3 install miflora
sudo pip3 install mitemp_bt
sudo pip3 install vesync-outlet


echo "CONFIGURE UWSGI"
echo "---------------------------------------------------------"
sudo cp ./uwsgi/potnanny.ini /etc/uwsgi/apps-available
sudo ln -s /etc/uwsgi/apps-available/potnanny.ini /etc/uwsgi/apps-enabled/potnanny.ini


echo "CONFIGURE NGINX"
echo "---------------------------------------------------------"
sudo cp ./nginx/default /etc/uwsgi/sites-available
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default


echo "CONFIGURE LOGROTATE"
echo "---------------------------------------------------------"
sudo sh -c 'cat ./logrotate.conf >>/etc/logrotate.conf'


echo "INSTALL WIRINGPI FROM SOURCE"
echo "---------------------------------------------------------"
cd /tmp
git clone git://git.drogon.net/wiringPi
cd wiringPi
git pull origin
./build


echo "INSTALL POTNANNY FROM SOURCE"
echo "---------------------------------------------------------"
cd /var/www
sudo git clone https://github.com/jeffleary00/potnanny.git
cd potnanny
sudo pip3 install -e .


echo "SET PERMISSIONS"
echo "---------------------------------------------------------"
sudo touch /var/www/potnanny/sqlite.db
sudo mkdir /var/www/potnanny/log
sudo touch /var/www/potnanny/log/poll.log
sudo chmod 660 /var/www/potnanny/log/poll.log
sudo usermod -a -G www-data $USER
cd /var/www
sudo chown -R www-data potnanny
sudo chgrp -R www-data potnanny
sudo chmod 660 /var/www/potnanny/sqlite.db


echo "RESTART WEB SERVICES"
echo "---------------------------------------------------------"
sudo service nginx restart
sudo service uwsgi restart


echo "INSTALL POTNANNY CRON JOB"
echo "---------------------------------------------------------"
sudo touch /var/spool/cron/crontabs/$USER
sudo cat /var/spool/cron/crontabs/$USER | grep "poll.py"
if [ $? -ne 0 ]; then
    sudo sh -c "echo '* * * * * /var/www/potnanny/bin/poll.py' >>/var/spool/cron/crontabs/$USER"
fi


echo "========================================================="
echo "COMPLETE"
echo "========================================================="
