# L6 Operations, Capacity, Certificates, Backups, And Drift

Goal: capacity, errors, logs, certificates, backups, monitoring, package posture, container posture, obvious cleanup candidates, and cross-host drift.

## Read-Only Checks

```bash
df -hT
df -ih
findmnt
free -h
uptime
ps aux --sort=-%mem | head -30
ps aux --sort=-%cpu | head -30
journalctl -p err -n 50 --no-pager
journalctl -p warning..alert -n 200 --no-pager
du -xhd1 / 2>/dev/null | sort -h
du -xhd1 /var 2>/dev/null | sort -h
du -xhd1 /home 2>/dev/null | sort -h
du -xhd1 /opt 2>/dev/null | sort -h
find /var/log -xdev -type f -size +100M -printf '%s %p\n' 2>/dev/null | sort -n
find /tmp /var/tmp -xdev -mindepth 1 -maxdepth 2 -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -100
find /etc/letsencrypt /etc/ssl /opt /srv -maxdepth 5 -type f \( -name '*.crt' -o -name '*.pem' \) -printf '%p\n' 2>/dev/null
find /etc/letsencrypt /etc/ssl /opt /srv -maxdepth 5 -type f \( -name '*.crt' -o -name '*.pem' \) -print0 2>/dev/null | xargs -0 -n1 sh -c 'openssl x509 -in "$1" -noout -subject -issuer -dates 2>/dev/null | sed "s|^|$1 |"' sh
systemctl list-timers --all --no-pager | egrep -i 'backup|borg|restic|rsync|duplicity|snapshot|dump' || true
systemctl list-units --all --no-pager | egrep -i 'backup|borg|restic|rsync|duplicity|snapshot|prometheus|node_exporter|datadog|telegraf|zabbix|netdata|grafana|loki|promtail|vector|fluent' || true
find /etc /opt /srv /home -maxdepth 4 \( -iname '*backup*' -o -iname '*borg*' -o -iname '*restic*' \) 2>/dev/null
apt-key list 2>/dev/null
find /etc/apt -maxdepth 4 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
command -v docker podman containerd ctr crictl kubectl helm goss ansible-playbook 2>/dev/null
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null
docker inspect --format '{{.Name}} Privileged={{.HostConfig.Privileged}} User={{.Config.User}} NetworkMode={{.HostConfig.NetworkMode}} PidMode={{.HostConfig.PidMode}} CapAdd={{.HostConfig.CapAdd}} SecurityOpt={{.HostConfig.SecurityOpt}} Binds={{.HostConfig.Binds}}' $(docker ps -q 2>/dev/null) 2>/dev/null
docker info 2>/dev/null
ls -l /var/run/docker.sock 2>/dev/null
grep -RIlE '(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|PRIVATE_KEY|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY|api[_-]?key|token|password=)' /etc /home /opt /srv 2>/dev/null
```

## Interpretation

- Cleanup candidates are recommendations only. Do not delete, truncate, vacuum, prune, or move anything.
- Backup existence is not restore assurance. Restore integrity is `blocked` unless restore-test evidence exists or the user authorizes testing.
- Docker socket, privileged containers, host networking, host PID, added capabilities, insecure binds, and root users are container escape indicators.
- Secret scans must report file paths only, not matched values.
- Cross-host drift should compare OS/kernel, services, timers, ports, users, SSH, sysctl, AppArmor/auditd, packages, repos, containers, backup/monitoring, disk layout, and log errors.
