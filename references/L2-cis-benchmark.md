# L2 CIS Benchmark, Kernel, And System Maintenance

Goal: CIS-style Ubuntu 24.04 evidence for filesystem posture, services, network parameters, logging/auditing, access control, and system maintenance.

## CIS Mapping

- CIS 1 Initial Setup: filesystems, partitions, unnecessary software.
- CIS 2 Services: active services without clear justification.
- CIS 3 Network: kernel network parameters, firewall, IPv6 posture.
- CIS 4 Logging And Auditing: auditd, journald, syslog visibility.
- CIS 5 Access Control: PAM, SSH config, sudo, accounts.
- CIS 6 System Maintenance: file permissions, integrity tooling, SUID/SGID.

## Read-Only Checks

```bash
find / -xdev -perm /6000 -type f -ls 2>/dev/null
find / -xdev -type f -perm -0002 -ls 2>/dev/null
sysctl net.ipv4.tcp_syncookies kernel.randomize_va_space net.ipv4.ip_forward net.ipv6.conf.all.forwarding kernel.dmesg_restrict kernel.kptr_restrict kernel.yama.ptrace_scope fs.suid_dumpable kernel.core_pattern 2>/dev/null
aa-status 2>/dev/null || true
sestatus 2>/dev/null || true
auditctl -s 2>/dev/null
auditctl -l 2>/dev/null
systemctl status auditd apparmor --no-pager 2>/dev/null
systemctl --failed --no-pager
systemctl list-units --type=service --state=running --no-pager
systemctl list-unit-files --type=service --state=enabled --no-pager
systemctl list-timers --all --no-pager
systemctl status bluetooth cups avahi-daemon rpcbind nfs-server smbd --no-pager 2>/dev/null
apt list --upgradable 2>/dev/null
systemctl status unattended-upgrades apt-daily.timer apt-daily-upgrade.timer --no-pager 2>/dev/null
dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\n' 2>/dev/null
snap list 2>/dev/null
flatpak list 2>/dev/null
for u in $(cut -f1 -d: /etc/passwd); do crontab -u "$u" -l 2>/dev/null | sed "s/^/[$u] /"; done
find /etc/cron* /var/spool/cron /var/spool/cron/crontabs -maxdepth 3 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
lsmod
command -v aide rkhunter debsums lynis usg 2>/dev/null
lynis show version 2>/dev/null
usg --version 2>/dev/null
rkhunter --versioncheck 2>/dev/null
```

## Tool Policy

- Do not run `apt update`, `apt install`, `usg fix`, hardening playbooks, or remediation commands.
- Lynis/USG/rkhunter often write reports/logs; report availability/version unless a no-write/no-log mode is confirmed.
- `debsums -c` and `aide --check` may be considered only if no-write behavior is confirmed and the user accepts runtime cost.
- If USG is absent, official CIS L1/L2 audit is `blocked`; native checks remain `partial`.
