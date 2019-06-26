#!/bin/bash

sudo mv /tmp/puma.service /lib/systemd/system/puma.service &&

cd /opt && git clone -b monolith https://github.com/express42/reddit.git && 
cd reddit && bundle install

sudo systemctl daemon-reload &&
systemctl start puma.service &&
sudo systemctl enable puma.service
