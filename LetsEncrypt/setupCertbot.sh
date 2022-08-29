#!/bin/bash

LE_CERT_GRP=ssl-cert
DOMAIN=domain.acme.com
#Users to add to the LE_CERT_GRP group
APP_USERS=(node_exporter)

APACHE=false
DRY_RUN=false
#PORT=443
PORT=80

#add-apt-repository ppa:certbot/certbot


if $APACHE
then
    echo "Installing Certbot and Apache plugin"
    apt install certbot acl python3-certbot-apache

    echo "Running Certbot for domain $DOMAIN"
    if $DRY_RUN
    then
        certbot -d $DOMAIN --apache certonly --dry-run
    else
        certbot -d $DOMAIN --apache certonly
    fi

    echo "Adding post-hook to certbot renew service"
    #Cron job replaced with systemctl enable certbot.timer on ubuntu
    if ! grep -Fxq "ExecStart=/usr/bin/certbot -q renew" /lib/systemd/system/certbot.service
    then
        sed -i 's/ExecStart=\/usr\/bin\/certbot -q renew/ExecStart=\/usr\/bin\/certbot -q renew --post-hook "systemctl reload apache2"/g' /lib/systemd/system/certbot.service
    fi
else
    echo "Installing Certbot"
    apt install certbot acl

    echo "Running standalone Certbot for domain $DOMAIN"
    if $DRY_RUN
    then
        certbot certonly --standalone --preferred-challenges http -d $DOMAIN --dry-run
    else
        certbot certonly --standalone --preferred-challenges http -d $DOMAIN
    fi
fi

echo "Opening local firewall port $PORT"
ufw allow $PORT

echo "Starting Certbot Renew Timer Service"
systemctl enable certbot.timer
systemctl start certbot.timer

echo "Creating group $LE_CERT_GRP"
groupadd -f $LE_CERT_GRP
for t in ${APP_USERS[@]}; do
    echo "Adding user $t to SSL Group $LE_CERT_GRP"
    usermod -a -G $LE_CERT_GRP $t
done


echo "Updating Certificate Permissions"
chgrp -R $LE_CERT_GRP /etc/letsencrypt/archive/$DOMAIN/
chgrp -R $LE_CERT_GRP /etc/letsencrypt/live/$DOMAIN/
chgrp $LE_CERT_GRP /etc/letsencrypt/archive/
chgrp $LE_CERT_GRP /etc/letsencrypt/live/

chmod g+r -R /etc/letsencrypt/archive/$DOMAIN/
chmod g+r -R /etc/letsencrypt/live/$DOMAIN/
chmod g+rx /etc/letsencrypt/archive/
chmod g+rx /etc/letsencrypt/live/


#setfacl -R -m g:$LE_CERT_GRP:rX /etc/letsencrypt/live/$DOMAIN/
#setfacl -R -m g:$LE_CERT_GRP:rX /etc/letsencrypt/archive/$DOMAIN/
#setfacl -m g:$LE_CERT_GRP:rX /etc/letsencrypt/live/
#setfacl -m g:$LE_CERT_GRP:rX /etc/letsencrypt/archive/

echo "Done"
