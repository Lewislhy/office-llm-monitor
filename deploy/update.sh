#!/bin/bash
# Pull-based deploy. GitHub holds no key to this box and nothing reaches in from outside:
# the box looks at the repo, and when main has moved it updates itself.
#
# Installed by deploy/install.sh as a systemd timer that runs every minute.
set -euo pipefail

REPO="${REPO:-/home/efficient/office-llm-monitor}"
UNIT="${UNIT:-llm-monitor}"
HEALTH="${HEALTH:-http://127.0.0.1:8765/live}"

cd "$REPO"
git fetch --quiet origin main
local_sha=$(git rev-parse HEAD)
remote_sha=$(git rev-parse origin/main)
[ "$local_sha" = "$remote_sha" ] && exit 0

echo "updating $local_sha -> $remote_sha"
git reset --hard --quiet origin/main

# Never deploy something that cannot even compile.
if ! python3 -m compileall -q llm_monitor.py; then
  echo "new commit does not compile, rolling back"
  git reset --hard --quiet "$local_sha"
  exit 1
fi

sudo systemctl restart "$UNIT"

for i in $(seq 1 20); do
  sleep 2
  if curl -fsS --max-time 3 "$HEALTH" >/dev/null 2>&1; then
    echo "deployed $remote_sha"
    exit 0
  fi
done

echo "health check never passed, rolling back to $local_sha"
git reset --hard --quiet "$local_sha"
sudo systemctl restart "$UNIT"
exit 1
