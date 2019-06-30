#!/bin/sh
set -e
cd ~
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
cat > /etc/systemd/system/puma.service <<EOF
[Unit]
Description=Puma-Server
After=network.target
[Service]
Type=simple
WorkingDirectory=/home/alexmar/reddit/
ExecStart=/usr/local/bin/puma
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start puma
systemctl enable puma 
