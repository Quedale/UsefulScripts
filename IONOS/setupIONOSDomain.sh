DOMAIN=www.acme.com

apt update
apt upgrade
apt install python3 python3-pip software-properties-common

pip install domain-connect-dyndns

domain-connect-dyndns setup --domain $DOMAIN
domain-connect-dyndns update --all
