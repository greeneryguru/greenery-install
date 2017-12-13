#!/bin/bash

#
# 
# Raspberry Pi setup script for greenery.guru enviro automation tool.
#
#

# base installs
sudo apt-get update
sudo apt-get -y install build-essential
sudo apt-get -y install sqlite3
sudo apt-get -y install python3-dev
sudo apt-get -y install python3-cryptography
sudo apt-get -y install python3-pip


# webserver
sudo apt-get -y install nginx
sudo apt-get -y install uwsgi
sudo apt-get -y install uwsgi-plugin-python3


# flask requirements
sudo pip3 install requests
sudo pip3 install flask
sudo pip3 install flask-login
sudo pip3 install flask-wtf
sudo pip3 install flask-sqlalchemy
sudo pip3 install wtforms_components
sudo pip3 install sqlalchemy-migrate
sudo pip3 install sqlalchemy_utils
sudo pip3 install pyserial
sudo pip3 install twilio


# download greenery app
sudo git clone https://github.com/jeffleary00/greenery.git /var/www/greenery


# configure web interface uwsgi/nginx
sudo chown -R www-data /var/www 
sudo chgrp -R www-data /var/www
if [ -f /etc/nginx/sites-available/default ]; then
   sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
fi
sudo cp /var/www/greenery/install/www/nginx.default /etc/nginx/sites-available/default
if [ -f /etc/nginx/sites-enabled/default ]; then
   sudo rm /etc/nginx/sites-enabled/default
fi
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sudo cp /var/www/greenery/install/www/uwsgi.ini /etc/uwsgi/apps-available/uwsgi.ini
if [ -f /etc/uwsgi/apps-enabled/uwsgi.ini ]; then
   sudo rm /etc/uwsgi/apps-enabled/uwsgi.ini
fi
sudo ln -s /etc/uwsgi/apps-available/uwsgi.ini /etc/uwsgi/apps-enabled/uwsgi.ini


# inital app db
sudo ls -l /var/www/greenery/app.db
catch=$?
if (( catch )); then
    sudo cp /var/www/greenery/initial.db /var/www/greenery/app.db
    sudo chown www-data /var/www/greenery/app.db
    sudo chgrp www-data /var/www/greenery/app.db
fi


# restart services
sudo service uwsgi restart
sudo service nginx restart


# install base crontab file for www-data
sudo ls -l /var/spool/cron/crontabs/www-data
catch=$?
if (( catch )); then
    cd /var/www/greenery
    sudo cp ./install/cron/www.cron /var/spool/cron/crontabs/www-data
    sudo chown www-data /var/spool/cron/crontabs/www-data
    sudo chmod 600 /var/spool/cron/crontabs/www-data
fi


# error log file that app should write to
sudo ls -l /var/tmp/greenery.errors.log
catch=$?
if (( catch )); then
    sudo -u www-data touch /var/tmp/greenery.errors.log
fi


# add www-data to group dialout, so /dev/ttyUSB is usable
sudo adduser www-data dialout


# success?
echo "OK!"

