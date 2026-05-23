# L5 EU Compliance Evidence Map

This audit provides technical evidence mapping, not legal certification. For every framework, classify evidence as `checked`, `partial`, `blocked`, or `not applicable/unknown`, and explain why.

## GDPR Art. 32

Evidence goals: encryption, confidentiality, integrity, availability, resilience, breach detection, restore capability, and log retention.

```bash
lsblk -f
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS
dmsetup ls --tree 2>/dev/null
for d in /dev/mapper/*; do test -e "$d" && cryptsetup status "$(basename "$d")" 2>/dev/null; done
grep -RInE 'ssl_protocols|SSLProtocol|TLSv1|TLSv1.1|TLSv1.2|TLSv1.3' /etc/nginx /etc/apache2 /etc/haproxy /etc/traefik 2>/dev/null
grep -RInE 'access_log|error_log|CustomLog|ErrorLog|log_format' /etc/nginx /etc/apache2 2>/dev/null
journalctl --disk-usage 2>/dev/null
journalctl --list-boots --no-pager 2>/dev/null
find /etc/logrotate* -maxdepth 4 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
systemctl status auditd rsyslog syslog-ng journald promtail vector fluent-bit datadog-agent wazuh-agent ossec --no-pager 2>/dev/null
```

Do not conclude pseudonymization from server config alone unless application log formats prove it. Restore testing is `blocked` unless documented evidence exists or the user authorizes a restore test.

## NIS2 Art. 21

Map host evidence to incident detection, business continuity, supply chain, vulnerability management, access control, cryptography, and asset inventory. Governance artifacts such as risk register, vendor register, incident response plan, and policy documents are `blocked: requires external governance evidence` if absent from host-visible docs.

## CRA

Evidence goals: security by default, vulnerability handling, SBOM/package inventory, no default credentials, exposed services, and support/update posture.

```bash
dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\n' 2>/dev/null
apt list --upgradable 2>/dev/null
find /etc/apt -maxdepth 4 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
grep -RIlE '(password.*admin|password.*default|default.*password|admin:admin|changeme|ChangeMe|123456)' /etc /opt /srv /home 2>/dev/null
ss -tulpen
systemctl status unattended-upgrades --no-pager 2>/dev/null
find /etc /opt /srv -maxdepth 5 -iname '*vulnerab*' -o -iname '*security*policy*' -o -iname '*disclosure*' -o -iname '*sbom*' 2>/dev/null
```

Do not write SBOM files to the server. Default-credential scans report file paths only, not values.

## DORA

Evidence goals: ICT asset register, incident classification, resilience testing evidence, concentration risk, monitoring, backup/restore, and operational ownership.

```bash
find /etc /opt /srv /home -maxdepth 5 \( -iname '*asset*' -o -iname '*inventory*' -o -iname '*incident*' -o -iname '*ir-plan*' -o -iname '*continuity*' -o -iname '*bcp*' -o -iname '*drp*' -o -iname '*tlpt*' -o -iname '*restore*' -o -iname '*backup*test*' \) 2>/dev/null
hostnamectl
systemctl list-units --all --no-pager | egrep -i 'backup|monitor|prometheus|node_exporter|datadog|zabbix|wazuh|ossec|netdata|grafana|loki|promtail|vector|fluent|falco|tetragon' || true
```

Do not infer DORA applicability from a host alone. Mark applicability as `unknown` unless business context says the host serves financial entities.

## BSI IT-Grundschutz

Evidence goals: SYS.1.3 Linux server controls, OPS.1.1.3 patch management, NET.1.1 segmentation, CON.3 data management.

```bash
cat /etc/issue /etc/issue.net 2>/dev/null
grep -RInE 'TMOUT|umask|PASS_MAX_DAYS|PASS_MIN_DAYS|pam_pwquality|pam_faillock|pam_tally|pam_google_authenticator|pam_u2f|pam_oath' /etc/login.defs /etc/profile /etc/profile.d /etc/pam.d 2>/dev/null
sysctl kernel.randomize_va_space kernel.yama.ptrace_scope fs.suid_dumpable kernel.core_pattern 2>/dev/null
sh -lc 'ulimit -c'
systemctl status systemd-coredump apport --no-pager 2>/dev/null
lsattr /var/log/auth.log /var/log/syslog /var/log/journal 2>/dev/null
find /etc /opt /srv -maxdepth 5 \( -iname '*patch*' -o -iname '*change*log*' -o -iname '*runbook*' -o -iname '*grundschutz*' -o -iname '*segmentation*' -o -iname '*retention*' -o -iname '*destroy*' -o -iname '*wipe*' \) 2>/dev/null
```

Report login banner, core dump posture, ASLR, ptrace, SoD indicators, NTP validity, log immutability indicators, idle timeout, patch documentation, and segmentation evidence. Do not set `chattr +a`, `TMOUT`, banners, sysctls, or PAM settings.

## ISO 27001 Evidence Areas

Map observed evidence to access control, cryptography, operations security, asset management, supplier/supply chain, and incident management. ISMS documents, risk acceptance, policies, ownership records, and audit trails are `blocked` if not host-visible.
