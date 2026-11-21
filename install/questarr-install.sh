#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Doezer
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/Doezer/Questarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "questarr" "Doezer/Questarr" "tarball"

msg_info "Building Questarr"
cd /opt/questarr
$STD npm ci --ignore-scripts
$STD npm rebuild better-sqlite3
$STD npm run build
$STD npm prune --omit=dev --ignore-scripts
mkdir -p /opt/questarr/data
cat <<EOF2 >/opt/questarr/.env
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
SQLITE_DB_PATH=/opt/questarr/data/sqlite.db
EOF2
msg_ok "Built Questarr"

msg_info "Creating Service"
cat <<EOF2 >/etc/systemd/system/questarr.service
[Unit]
Description=Questarr Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/questarr
EnvironmentFile=/opt/questarr/.env
ExecStart=/usr/bin/node /opt/questarr/dist/server/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF2
systemctl enable -q --now questarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
