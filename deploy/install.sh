#!/bin/bash
# Run once on a new box, as root: sudo deploy/install.sh
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)

install -m 644 "$HERE/llm-monitor.service"        /etc/systemd/system/
install -m 644 "$HERE/llm-monitor-update.service" /etc/systemd/system/
install -m 644 "$HERE/llm-monitor-update.timer"   /etc/systemd/system/

# the updater restarts the service, so let it do exactly that and nothing else
cat > /etc/sudoers.d/llm-monitor-update <<'SUDO'
efficient ALL=(root) NOPASSWD: /bin/systemctl restart llm-monitor
SUDO
chmod 440 /etc/sudoers.d/llm-monitor-update

systemctl daemon-reload
systemctl enable --now llm-monitor.service
systemctl enable --now llm-monitor-update.timer
systemctl status llm-monitor --no-pager | head -5
