GIT_FOLDER="~/git"
PROM_LOC="$GIT_FOLDER/node_exporter"
DOMAIN=www.acme.com

BASIC_USER=user
BASIC_PASS="PUT HASH PASSWORD HERE"

mkdir $GIT_FOLDER
cd $GIT_FOLDER

GO_WF=/tmp
rm -r $GO_WF/go
mkdir $GO_WF/go

wget https://go.dev/dl/go1.18.4.linux-amd64.tar.gz
tar -C $GO_WF -xzf go1.18.4.linux-amd64.tar.gz
#wget https://go.dev/dl/go1.17.6.linux-arm64.tar.gz
#tar -C $GO_WF -xzf go1.17.6.linux-arm64.tar.gz

export PATH=$PATH:$GO_WF/go/bin

git clone https://github.com/prometheus/node_exporter.git

cd node_exporter

make build

useradd --no-create-home --shell /bin/false node_exporter

mkdir /etc/node_exporter
chown node_exporter:node_exporter /etc/node_exporter
touch "/etc/node_exporter/web.yml"

echo "# TLS and basic authentication configuration example." > "/etc/node_exporter/web.yml"
echo "#" >> "/etc/node_exporter/web.yml"
echo "# Additionally, a certificate and a key file are needed." >> "/etc/node_exporter/web.yml"
echo "tls_server_config:" >> "/etc/node_exporter/web.yml"
echo "  cert_file: /etc/letsencrypt/live/$DOMAIN/fullchain.pem" >> "/etc/node_exporter/web.yml"
echo "  key_file: /etc/letsencrypt/live/$DOMAIN/privkey.pem" >> "/etc/node_exporter/web.yml"
echo "" >> "/etc/node_exporter/web.yml"
echo "# Usernames and passwords required to connect to Prometheus." >> "/etc/node_exporter/web.yml"
echo "# Passwords are hashed with bcrypt: https://github.com/prometheus/exporter-toolkit/blob/master/docs/web-configuration.md#about-bcrypt" >> "/etc/node_exporter/web.yml"
echo "basic_auth_users:" >> "/etc/node_exporter/web.yml"
echo "  $BASIC_USER: $BASIC_PASS" >> "/etc/node_exporter/web.yml"

cp $PROM_LOC/node_exporter /usr/local/bin/

chown node_exporter:node_exporter /usr/local/bin/node_exporter

touch /etc/systemd/system/node_exporter.service

echo "[Unit]" > "/etc/systemd/system/node_exporter.service"
echo "Description=Node Exporter" >> "/etc/systemd/system/node_exporter.service"
echo "Wants=network-online.target" >> "/etc/systemd/system/node_exporter.service"
echo "After=network-online.target" >> "/etc/systemd/system/node_exporter.service"
echo "" >> "/etc/systemd/system/node_exporter.service"
echo "[Service]" >> "/etc/systemd/system/node_exporter.service"
echo "User=node_exporter" >> "/etc/systemd/system/node_exporter.service"
echo "Group=node_exporter" >> "/etc/systemd/system/node_exporter.service"
echo "Type=simple" >> "/etc/systemd/system/node_exporter.service"
echo "ExecStart=/usr/local/bin/node_exporter --web.config /etc/node_exporter/web.yml" >> "/etc/systemd/system/node_exporter.service"
echo "" >> "/etc/systemd/system/node_exporter.service"
echo "[Install]" >> "/etc/systemd/system/node_exporter.service"
echo "WantedBy=multi-user.target" >> "/etc/systemd/system/node_exporter.service"

systemctl daemon-reload

usermod -a -G ssl-cert node_exporter

systemctl start node_exporter

