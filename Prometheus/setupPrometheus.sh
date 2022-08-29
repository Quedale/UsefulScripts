GIT_FOLDER="~/git"
PROM_LOC="$GIT_FOLDER/prometheus"
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

git clone https://github.com/prometheus/prometheus.git

cd prometheus

make build

useradd --no-create-home --shell /bin/false prometheus

mkdir /etc/prometheus
chown prometheus:prometheus /etc/prometheus

touch "/etc/prometheus/prometheus.yml"

echo "global:" > "/etc/prometheus/prometheus.yml"
echo "  scrape_interval:     5s # By default, scrape targets every 5 seconds." >> "/etc/prometheus/prometheus.yml"
echo "" >> "/etc/prometheus/prometheus.yml"
echo "  # Attach these labels to any time series or alerts when communicating with" >> "/etc/prometheus/prometheus.yml"
echo "  # external systems (federation, remote storage, Alertmanager)." >> "/etc/prometheus/prometheus.yml"
echo "  external_labels:" >> "/etc/prometheus/prometheus.yml"
echo "    monitor: 'prometheus-monitor'" >> "/etc/prometheus/prometheus.yml"
echo "" >> "/etc/prometheus/prometheus.yml"
echo "# A scrape configuration containing exactly one endpoint to scrape:" >> "/etc/prometheus/prometheus.yml"
echo "# Here it's Prometheus itself." >> "/etc/prometheus/prometheus.yml"
echo "scrape_configs:" >> "/etc/prometheus/prometheus.yml"
echo "  # The job name is added as a label job=<job_name> to any timeseries scraped from this config." >> "/etc/prometheus/prometheus.yml"
echo "  - job_name: 'prometheus'" >> "/etc/prometheus/prometheus.yml"
echo "    scheme: https" >> "/etc/prometheus/prometheus.yml"
echo "" >> "/etc/prometheus/prometheus.yml"
echo "    # Override the global default and scrape targets from this job every 5 seconds." >> "/etc/prometheus/prometheus.yml"
echo "    static_configs:" >> "/etc/prometheus/prometheus.yml"
echo "      - targets: ['$DOMAIN:9091']" >> "/etc/prometheus/prometheus.yml"

touch "/etc/prometheus/web.yml"

echo "# TLS and basic authentication configuration example." > "/etc/prometheus/web.yml"
echo "#" >> "/etc/prometheus/web.yml"
echo "# Additionally, a certificate and a key file are needed." >> "/etc/prometheus/web.yml"
echo "tls_server_config:" >> "/etc/prometheus/web.yml"
echo "  cert_file: /etc/letsencrypt/live/$DOMAIN/fullchain.pem" >> "/etc/prometheus/web.yml"
echo "  key_file: /etc/letsencrypt/live/$DOMAIN/privkey.pem" >> "/etc/prometheus/web.yml"
echo "" >> "/etc/prometheus/web.yml"
echo "# Usernames and passwords required to connect to Prometheus." >> "/etc/prometheus/web.yml"
echo "# Passwords are hashed with bcrypt: https://github.com/prometheus/exporter-toolkit/blob/master/docs/web-configuration.md#about-bcrypt" >> "/etc/prometheus/web.yml"
echo "basic_auth_users:" >> "/etc/prometheus/web.yml"
echo "  $BASIC_USER: $BASIC_PASS" >> "/etc/prometheus/web.yml"

cp $PROM_LOC/prometheus /usr/local/bin/

chown prometheus:prometheus /usr/local/bin/prometheus

touch /etc/systemd/system/prometheus.service

echo "[Unit]" > "/etc/systemd/system/prometheus.service"
echo "Description=Prometheus" >> "/etc/systemd/system/prometheus.service"
echo "Wants=network-online.target" >> "/etc/systemd/system/prometheus.service"
echo "After=network-online.target" >> "/etc/systemd/system/prometheus.service"
echo "" >> "/etc/systemd/system/prometheus.service"
echo "[Service]" >> "/etc/systemd/system/prometheus.service"
echo "WorkingDirectory=/etc/prometheus" >> "/etc/systemd/system/prometheus.service"
echo "User=prometheus" >> "/etc/systemd/system/prometheus.service"
echo "Group=prometheus" >> "/etc/systemd/system/prometheus.service"
echo "Type=simple" >> "/etc/systemd/system/prometheus.service"
echo "ExecStart=/usr/local/bin/prometheus --web.config.file=/etc/prometheus/web.yml --config.file=/etc/prometheus/prometheus.yml --web.listen-address=:9091" >> "/etc/systemd/system/prometheus.service"
echo "" >> "/etc/systemd/system/prometheus.service"
echo "[Install]" >> "/etc/systemd/system/prometheus.service"
echo "WantedBy=multi-user.target" >> "/etc/systemd/system/prometheus.service"

systemctl daemon-reload

usermod -a -G ssl-cert prometheus

systemctl start prometheus

