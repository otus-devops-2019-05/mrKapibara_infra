#!/bin/bash

sudo mv /tmp/puma.service /lib/systemd/system/puma.service &&

cd /opt && sudo git clone -b monolith https://github.com/express42/reddit.git && 
cd reddit && bundle install

sudo systemctl daemon-reload &&
sudo systemctl start puma.service &&
sudo systemctl enable puma.service
