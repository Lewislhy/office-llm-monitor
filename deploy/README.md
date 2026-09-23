# Deploying

The box pulls; nothing pushes into it. There is no deploy key on GitHub, no runner, and no
inbound port — which is why this works on a machine that only exists inside a tailnet.

```
you: git push main
                          ┌── every 60s ──┐
                          ▼               │
box: git fetch → moved? → git reset --hard → compiles? → restart → healthy?
                                              │ no          │ no
                                              └── roll back ┘
```

`deploy/update.sh` refuses to leave the service down: if the new commit does not compile, or
the page does not answer within 40 seconds of the restart, it puts the previous commit back
and restarts again.

## First install on a new box

```bash
git clone https://github.com/<owner>/office-llm-monitor ~/office-llm-monitor
cd ~/office-llm-monitor && sudo deploy/install.sh
```

## Checking on it

```bash
systemctl status llm-monitor          # the page itself
systemctl list-timers llm-monitor-update
journalctl -u llm-monitor-update -n 30   # what the last few deploys did
```

## The database

History lives in `/home/efficient/qwen-monitor/monitor.db`, outside the checkout, so a deploy
never touches it and a rollback never loses it.
