#!/bin/bash

# -----------------------------------------------------------------------------
#
# Run this script as the 'pi' user on Raspberry Pi
#
# Synopsis:
# pi@raspberrypi:$  bash ./install.bash
#
# -----------------------------------------------------------------------------

FAILURES=0

echo "---------------------------------------------------------"
echo "INSTALL SYSTEM LIBRARIES AND APPLICATIONS"
echo "---------------------------------------------------------"
sudo apt-get update
if [ $? != 0 ]; then
  echo " COMMAND FAILED: !!"
  ((FAILURES+=1));
fi

PKGLIST="
  build-essential
  libglib2.0-dev
  libbluetooth-dev
  git
  python3-dev
  python3-cryptography
  python3-pip
  nginx
  uwsgi
  uwsgi-plugin-python3
  sqlite3
  nodejs
  npm"

for PKG in $PKGLIST
do
  sudo apt-get -y install $PKG
  if [ $? != 0 ]; then
    echo " COMMAND FAILED: !!"
    ((FAILURES+=1));
  fi
done


echo "---------------------------------------------------------"
echo "INSTALL BASE PYTHON MODULES"
echo "---------------------------------------------------------"
PKGLIST="
  click
  dotenv
  passlib
  sqlalchemy
  marshmallow
  jinja2
  virtualenv
  requests
  passlib
  sqlalchemy
  marshmallow
  flask
  flask-restful
  flask-jwt-extended"

for PKG in $PKGLIST
do
  sudo pip3 install $PKG
  if [ $? != 0 ]; then
    echo " COMMAND FAILED: !!"
    ((FAILURES+=1));
  fi
done


echo "---------------------------------------------------------"
echo "INSTALL WIRINGPI FROM SOURCE"
echo "---------------------------------------------------------"
cd ~
git clone git://git.drogon.net/wiringPi
cd wiringPi
git pull origin
sudo ./build
if [ $? != 0 ]; then
  echo " COMMAND FAILED: !!"
  ((FAILURES+=1));
fi


echo "---------------------------------------------------------"
echo "ADD USER TO www-data GROUP"
echo "---------------------------------------------------------"
sudo usermod -a -G www-data $USER
if [ $? != 0 ]; then
  echo " COMMAND FAILED: !!"
  ((FAILURES+=1));
fi


echo "---------------------------------------------------------"
echo "SETUP POTNANNY DIRECTORIES"
echo "---------------------------------------------------------"
DIRLIST="
  /var/log/potnanny
  /var/local/potnanny
  /opt/potnanny
  /opt/potnanny/plugins
  /opt/potnanny/plugins/action
  /opt/potnanny/plugins/ble"

for DIR in $DIRLIST
do
  if [ ! -d $DIR ]; then
    sudo mkdir $DIR
    if [ $? != 0 ]; then
      echo " COMMAND FAILED: !!"
      ((FAILURES+=1));
    fi
  fi
  sudo chown root $DIR
  sudo chgrp www-data $DIR
  sudo chmod 775 $DIR
done


echo "---------------------------------------------------------"
echo "SETUP LOG FILES"
echo "---------------------------------------------------------"
LOGLIST="
  /var/log/potnanny/potnanny.log"

for FNAME in $LOGLIST
do
  if [ ! -e $FNAME ]; then
    sudo touch $FNAME
    if [ $? != 0 ]; then
      echo " COMMAND FAILED: !!"
      ((FAILURES+=1));
    fi
  fi
  sudo chown $USER $FNAME
  sudo chgrp www-data $FNAME
  sudo chmod 664 $FNAME
done


echo "---------------------------------------------------------"
echo "INSTALL POTNANNY CORE"
echo "---------------------------------------------------------"
# "--no-binary" must be used, to get around weird bug in setuptools, where all
# data_files are installed relative to package, in system python dir. this
# behavior is NOT what we want.
# This flag ensures non-package files get installed to correct filesystem paths.
sudo pip3 install --no-binary :all: potnanny-core
if [ $? != 0 ]; then
  echo " COMMAND FAILED: !!"
  ((FAILURES+=1));
fi


echo "---------------------------------------------------------"
echo "INSTALL WWW POTNANNY API"
echo "---------------------------------------------------------"
cd /var/www
sudo git clone https://github.com/jeffleary00/potnanny-api.git
if [ $? != 0 ]; then
  echo " COMMAND FAILED: !!"
  ((FAILURES+=1));
fi
sudo chown -R www-data potnanny-api
sudo chgrp -R www-data potnanny-api


# echo "---------------------------------------------------------"
# echo "INSTALL POTNANNY SINGLE PAGE APPLICATION"
# echo "---------------------------------------------------------"
# cd ~
# git clone https://github.com/jeffleary00/potnanny-spa.git
# cd potnanny-spa
# npm install
# npm run build
# sudo cp dist/* /var/www/html


echo "---------------------------------------------------------"
echo "CONFIGURE LOGROTATE"
echo "---------------------------------------------------------"
if [ ! -e "/etc/logrotate.conf" ]; then
  sudo touch /etc/logrotate.conf
fi
sudo sh -c 'cat ./logrotate/logrotate.conf >>/etc/logrotate.conf'
if [ $? != 0 ]; then
  echo " COMMAND FAILED: !!"
  ((FAILURES+=1));
fi


echo "---------------------------------------------------------"
echo "CONFIGURE UWSGI"
echo "---------------------------------------------------------"
sudo cp ./uwsgi/potnanny.ini /etc/uwsgi/apps-available
sudo ln -s /etc/uwsgi/apps-available/potnanny.ini /etc/uwsgi/apps-enabled/potnanny.ini


echo "---------------------------------------------------------"
echo "CONFIGURE NGINX"
echo "---------------------------------------------------------"
sudo cp ./nginx/default /etc/uwsgi/sites-available
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default


echo "---------------------------------------------------------"
echo "SET ADDITIONAL PERMISSIONS"
echo "---------------------------------------------------------"
DIRLIST="
  /opt/potnanny/plugins"

for DIR in $DIRLIST
do
  sudo chgrp -R www-data $DIR
  sudo chmod -R 775 $DIR
done

FLIST="
  /usr/local/bin/rf_send
  /usr/local/bin/rf_send"

for FNAME in $FLIST
do
  sudo chgrp www-data $FNAME
  sudo chmod 770 $FNAME
done


echo "---------------------------------------------------------"
echo "INSTALL POTNANNY CRON JOB"
echo "---------------------------------------------------------"
if [ ! -e /var/spool/cron/crontabs/$USER ]; then
  sudo touch /var/spool/cron/crontabs/$USER
fi
sudo cat /var/spool/cron/crontabs/$USER | grep "potnanny poll"
if [ $? -ne 0 ]; then
  sudo sh -c "echo '* * * * * potnanny poll' >>/var/spool/cron/crontabs/$USER"
fi
sudo chmod 0600 /var/spool/cron/crontabs/$USER
sudo chown $USER /var/spool/cron/crontabs/$USER


echo "---------------------------------------------------------"
echo "GENERATE SELF-SIGNED CERT FOR NGINX"
echo "HELP: You can enter just a '.' for each question"
echo "---------------------------------------------------------"
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt


echo "---------------------------------------------------------"
echo "GENERATE SSL DH GROUP FOR NGINX (background process)"
echo "---------------------------------------------------------"
sudo openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 2048 >/dev/null 2>&1 &
DHPID=$!


echo "---------------------------------------------------------"
echo "GENERATE SECRET KEYS FOR FLASK PRODUCTION ENVIRONMENT"
echo "---------------------------------------------------------"
if [ ! -e /etc/profile.d/flask.sh ]; then
  sudo touch /etc/profile.d/flask.sh
  KEYLIST="
    SECRET_KEY
    JWT_SECRET_KEY
  "
  for KEY in $KEYLIST
  do
    MYSECRET=`openssl rand -base64 32`
    sudo sh -c 'echo "export $KEY=$MYSECRET" >>/etc/profile.d/flask.sh'
  done
  source /etc/profile.d/flask.sh
fi


echo "---------------------------------------------------------"
echo "SETUP INITIAL POTNANNY DATABASE"
echo "---------------------------------------------------------"
touch /var/local/potnanny/potnanny.db
sudo chgrp www-data /var/local/potnanny/potnanny.db
sudo chmod 664 /var/local/potnanny/potnanny.db
potnanny db init


echo "---------------------------------------------------------"
echo "RESTART WWW SERVICES"
echo "---------------------------------------------------------"
while :
do
  RVAL=`ps -p $DHPID`
  if [ $? != 0 ]; then
    break
  else
    echo "waiting for SSL DH background process to finish. takes a long time..."
    sleep 60
  fi
done
sudo service nginx restart
if [ $? != 0 ]; then
  echo " COMMAND FAILED: !!"
  ((FAILURES+=1));
fi

sudo service uwsgi restart
if [ $? != 0 ]; then
  echo " COMMAND FAILED: !!"
  ((FAILURES+=1));
fi


echo ""
echo "========================================================="
echo "COMPLETE"
echo "========================================================="
if [ $FAILURES > 0 ]; then
  echo "WARNING!"
  echo "There were $FAILURES errors during install. System is not 100%."
  echo "Review log and correct any problems."
else
  echo "REBOOTING NOW..."
  sudo reboot now
fi
