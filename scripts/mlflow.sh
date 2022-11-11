#!/usr/bin/env bash
# run as root
echo "====== START ======"
sudo su
apt-get update
apt-get -y install python3 python3-dev python3-pip python3-wheel
pip install --upgrade pip
#apt-get install postgresql postgresql-contrib postgresql-server-dev-all
apt -y install postgresql postgresql-contrib
sudo systemctl start postgresql.service
# installing PostgreSQL and preparing the database / VERSION 9.5 (or higher)

echo "CREATE USER mlflow PASSWORD 'mlflow'; CREATE DATABASE mlflow; GRANT ALL PRIVILEGES ON DATABASE mlflow TO mlflow;" | sudo -u postgres psql
sudo -u postgres sed -i "s|#listen_addresses = 'localhost'|listen_addresses = '*'|" /etc/postgresql/*/main/postgresql.conf
sudo -u postgres sed -i "s|127.0.0.1/32|0.0.0.0/0|" /etc/postgresql/*/main/pg_hba.conf
sudo -u postgres sed -i "s|::1/128|::/0|" /etc/postgresql/*/main/pg_hba.conf
service postgresql restart

apt install gcc 
pip install psycopg2-binary
pip install mlflow


# create mlflow user with sudo capability
adduser mlflow --gecos "mlflow,,," --disabled-password
echo "mlflow:mlflow" | chpasswd
usermod -aG sudo mlflow
echo "mlflow ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

MLFLOW_HOME=/opt/mlflow

# airflow local
mkdir -p $MLFLOW_HOME
mkdir -p /var/log/mlflow $MLFLOW_HOME/mlruns
chmod -R 777 $MLFLOW_HOME
chown -R mlflow:mlflow $MLFLOW_HOME
chown mlflow /var/log/mlflow

# create a persistent varable for AIRFLOW across all users env
echo export MLFLOW_HOME=/opt/mlfloww > /etc/profile.d/mlflow.sh

sudo tee -a /tmp/mlflow_environment<<EOL
MLFLOW_HOME=/opt/mlflow
EOL

cat /tmp/mlflow_environment | sudo tee -a /etc/default/mlflow

echo "
[Unit]
Description=MLFlow Server

[Service]
Type=simple
EnvironmentFile=/etc/default/mlflow
ExecStart=mlflow server --backend-store-uri postgresql://mlflow:mlflow@localhost/mlflow --host 0.0.0.0 --default-artifact-root file:$MLFLOW_HOME
User=mlflow
Group=mlflow
Restart=always
RestartSec=10
#KillMode=mixed

[Install]
WantedBy=multi-user.target
" >> /tmp/mlflow.service

sudo cat /tmp/mlflow.service >> /etc/systemd/system/mlflow.service
sudo systemctl enable mlflow.service
sudo systemctl start mlflow.service

apt-get purge --auto-remove -yqqq
apt-get autoremove -yqq --purge
apt-get clean


chown -R mlflow:mlflow $MLFLOW_HOME
chown mlflow /var/log/mlflow
echo "====== END ======"