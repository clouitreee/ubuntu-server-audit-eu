---
name: ubuntu-server-audit-eu
description: Use when performing strict read-only SSH inspections of Ubuntu/Linux servers for MSP onboarding, EU cybersecurity compliance evidence, security posture, operational disorder, waste, drift, CIS-style hardening gaps, kernel/runtime visibility, identity/access, network exposure, backups, observability, and unknowns. Requires explicit coverage tracking, no state-changing commands, no secret disclosure, and a final evidence-backed report for each host plus cross-host drift.
metadata:
  short-description: Read-only Ubuntu/Linux audit with EU compliance evidence
---

# Ubuntu Server Audit EU

Use this skill for deep SSH-based Linux inspections where the user needs to know the real current state of servers before MSP operations. The audit must be transparent: every area is either checked, partially checked, blocked, or explicitly not checked.

## Absolute Rules

- Strict read-only mode by default. Do not modify files, services, packages, firewall, containers, users, logs, databases, or app state.
- Never run destructive or state-changing commands: `rm`, `rmdir`, `unlink`, `mv`, `cp` to server paths, `chmod`, `chown`, `truncate`, `tee`, redirects to files, package install/remove/upgrade, `apt update`, `systemctl restart/start/stop/enable/disable`, `docker rm/prune`, `journalctl --vacuum-*`, database writes, config edits, or remediation tools.
- Do not install Lynis, USG, Falco, Tetragon, AIDE, rkhunter, debsums, Goss, or any other tool during the audit.
- Do not run audit tools that write logs/reports/state by default unless a no-write/no-log mode is confirmed for that exact command. If no safe no-write mode is confirmed, report tool availability only and mark execution as `blocked: would write audit output/state`.
- Avoid `sudo` unless read-only visibility requires it. If `sudo` is needed, use informational commands only and note the reason.
- Do not print secrets: private keys, tokens, `.env` values, password hashes, API keys, certificate private keys, database passwords, cloud credentials, backup credentials. Prefer metadata: path, owner, mode, size, mtime, and redacted key names.
- Do not read protected local paths such as `/Users/rootml/Desktop/sensitive_drop/` unless explicitly authorized.
- Maintain a coverage ledger for every host and category: `checked`, `partial`, `blocked`, or `not checked`, with reason.

## Audit Objective

Answer these questions with evidence:

- What role does each server currently serve?
- What is exposed, privileged, stale, duplicated, failing, unpatched, unmonitored, undocumented, or wasteful?
- Which differences between hosts are expected vs risky drift?
- What prevents MSP onboarding today?
- What remains unknown after a read-only inspection?

## Preflight Per Host

Collect identity and baseline first:

```bash
hostnamectl
uname -a
date
uptime
whoami
id
pwd
lsb_release -a 2>/dev/null || cat /etc/os-release
systemd-detect-virt 2>/dev/null || true
```

Record SSH alias, hostname, OS, kernel, timezone, uptime, current user, privilege level, virtualization/container context, and command failures.

## Coverage Checklist

The final report must explicitly include an "Ubuntu Server 2026 Framework" section with Layers 0-6 below. Do not collapse these into generic findings; each layer must show status for each host and explain `partial` or `blocked` states.

### Layer 0: Modern Runtime / eBPF

Goal: determine whether kernel-level runtime detection exists and whether eBPF programs are loaded.

Read-only checks:

```bash
command -v falco tetragon cilium bpftrace bpftool 2>/dev/null
systemctl status falco tetragon cilium-agent --no-pager 2>/dev/null
bpftool prog list 2>/dev/null
bpftool map list 2>/dev/null
```

Report Falco, Tetragon, Cilium, bpftrace, and bpftool presence separately. Mark `partial` if some native visibility exists but runtime detection tools are absent. Mark `blocked` if eBPF visibility cannot be checked due to missing `bpftool` and insufficient permissions. Do not install or start tools.

### Layer 1: Kernel, Privileges, CIS-Style Hardening

Goal: privilege escalation surface, kernel hardening, MAC status, audit coverage, integrity signals.

Read-only checks:

```bash
find / -xdev -perm /6000 -type f -ls 2>/dev/null
sysctl net.ipv4.tcp_syncookies kernel.randomize_va_space net.ipv4.ip_forward net.ipv6.conf.all.forwarding kernel.dmesg_restrict kernel.kptr_restrict kernel.yama.ptrace_scope 2>/dev/null
aa-status 2>/dev/null || true
sestatus 2>/dev/null || true
auditctl -s 2>/dev/null
auditctl -l 2>/dev/null
systemctl status auditd apparmor --no-pager 2>/dev/null
command -v aide rkhunter debsums lynis usg 2>/dev/null
lsmod
```

If installed, these may be considered only when no-write/no-log behavior is confirmed:

```bash
debsums -c 2>/dev/null
aide --check 2>/dev/null
```

For tools commonly writing reports/logs, prefer availability/version only unless no-write behavior is verified:

```bash
command -v lynis usg rkhunter 2>/dev/null
lynis show version 2>/dev/null
usg --version 2>/dev/null
rkhunter --versioncheck 2>/dev/null
```

Do not run `apt install lynis -y`, `apt update`, `usg fix`, hardening scripts, remediation commands, or audit commands that write reports/logs.

The report must map evidence to CIS-style sections:

- CIS 1 Initial Setup: filesystems, partitions, unnecessary software.
- CIS 2 Services: active services without clear justification.
- CIS 3 Network: kernel network parameters, firewall, IPv6 posture.
- CIS 4 Logging & Auditing: auditd, journald, syslog visibility.
- CIS 5 Access Control: PAM, SSH config, sudo, accounts.
- CIS 6 System Maintenance: file permissions, integrity tooling, SUID/SGID.

If USG is absent, mark official CIS L1/L2 audit as `blocked` because the canonical tool is not installed. Still perform a best-effort CIS-style read-only assessment with native commands and mark it `partial`.

### Layer 2: Identity And Access

Goal: understand human/service identities, privilege paths, SSH posture, active sessions, and login anomalies.

Read-only checks:

```bash
getent passwd
grep -vE ':(/usr/sbin/nologin|/sbin/nologin|/bin/false)$' /etc/passwd 2>/dev/null
getent group sudo adm docker lxd systemd-journal 2>/dev/null
grep -R '^[^#].*ALL=' /etc/sudoers /etc/sudoers.d 2>/dev/null
sshd -T 2>/dev/null | egrep 'permitrootlogin|passwordauthentication|pubkeyauthentication|authorizedkeysfile|kexalgorithms|hostkeyalgorithms|pubkeyacceptedalgorithms|authenticationmethods|permitemptypasswords|maxauthtries'
command -v ssh-audit 2>/dev/null
grep -nE '^[[:space:]]*(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AuthorizedKeysFile|KexAlgorithms|HostKeyAlgorithms|PubkeyAcceptedAlgorithms|AuthenticationMethods|PermitEmptyPasswords|MaxAuthTries)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null
grep -RInE 'pam_google_authenticator|pam_oath|pam_u2f|pam_duo|auth required|AuthenticationMethods' /etc/pam.d /etc/ssh 2>/dev/null
last -n 20
lastlog
who
w
ss -tnp 2>/dev/null | grep ':22' || true
find /home /root -maxdepth 3 -name authorized_keys -type f -printf '%p %u %g %m %TY-%Tm-%Td %TH:%TM\n' 2>/dev/null
```

Do not print private keys. Do not dump full `authorized_keys` unless the user explicitly asks; metadata and counts are usually enough.

Report SSH algorithms explicitly: Ed25519/ECDSA/RSA, whether RSA appears allowed, and whether RSA minimum strength can be inferred. Report `AuthorizedKeysFile` paths and whether they are standard. Report MFA/PAM/TOTP as `present`, `absent`, `partial`, or `blocked`. If `ssh-audit` is already installed locally or remotely, it may be used as a read-only SSH protocol probe; do not install it during the audit.

### Layer 3: Network Exposure

Goal: every listening port has an owner and justification; firewall posture and egress blind spots are visible.

Read-only checks:

```bash
ip -br addr
ip route
ss -tulpen
ss -tnp state established 2>/dev/null
ufw status verbose 2>/dev/null
nft list ruleset 2>/dev/null
iptables -S 2>/dev/null
iptables -L -n -v 2>/dev/null
ip6tables -S 2>/dev/null
systemctl status fail2ban --no-pager 2>/dev/null
fail2ban-client status 2>/dev/null
find /etc/fail2ban -maxdepth 3 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
resolvectl status 2>/dev/null || cat /etc/resolv.conf
systemctl status systemd-resolved dnsmasq bind9 unbound --no-pager 2>/dev/null
```

Classify exposure as `public`, `private`, `loopback`, or `unknown` where possible. Note if egress filtering is absent or not inferable.

Report nftables and iptables separately and call out coexistence or inconsistencies. Egress filtering must be explicitly classified as `present`, `absent`, `unknown`, or `blocked`; do not omit it because it is commonly forgotten.

### Layer 4: System State And Maintenance

Goal: failed services, unnecessary services, patch posture, world-writable files, cron/timers, and package drift.

Read-only checks:

```bash
systemctl --failed --no-pager
systemctl list-units --type=service --state=running --no-pager
systemctl list-unit-files --type=service --state=enabled --no-pager
systemctl list-timers --all --no-pager
systemctl status bluetooth cups avahi-daemon rpcbind nfs-server smbd --no-pager 2>/dev/null
apt list --upgradable 2>/dev/null
systemctl status unattended-upgrades apt-daily.timer apt-daily-upgrade.timer --no-pager 2>/dev/null
dpkg -l 2>/dev/null
snap list 2>/dev/null
flatpak list 2>/dev/null
find / -xdev -type f -perm -0002 -ls 2>/dev/null
for u in $(cut -f1 -d: /etc/passwd); do crontab -u "$u" -l 2>/dev/null | sed "s/^/[$u] /"; done
find /etc/cron* /var/spool/cron /var/spool/cron/crontabs -maxdepth 3 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
```

Do not run `apt autoremove`, `apt clean`, package upgrades, or service disablement.

### Layer 5: Operations And Resource Surface

Goal: capacity, errors, logs, certificates, backups, monitoring, and obvious cleanup candidates.

Read-only checks:

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
```

TLS and backup signals:

```bash
find /etc/letsencrypt /etc/ssl /opt /srv -maxdepth 5 -type f \( -name '*.crt' -o -name '*.pem' \) -printf '%p\n' 2>/dev/null
find /etc/letsencrypt /etc/ssl /opt /srv -maxdepth 5 -type f \( -name '*.crt' -o -name '*.pem' \) -print0 2>/dev/null | xargs -0 -n1 sh -c 'openssl x509 -in "$1" -noout -subject -issuer -dates 2>/dev/null | sed "s|^|$1 |"' sh
systemctl list-timers --all --no-pager | egrep -i 'backup|borg|restic|rsync|duplicity|snapshot|dump' || true
systemctl list-units --all --no-pager | egrep -i 'backup|borg|restic|rsync|duplicity|snapshot|prometheus|node_exporter|datadog|telegraf|zabbix|netdata|grafana|loki|promtail|vector|fluent' || true
find /etc /opt /srv /home -maxdepth 4 -iname '*backup*' -o -iname '*borg*' -o -iname '*restic*' 2>/dev/null
```

Do not validate backups by restoring unless explicitly authorized. Report last backup evidence and whether restore integrity is `checked`, `partial`, or `blocked`. For certificates, inspect expiry without printing private key material.

### Layer 6: Supply Chain, Drift, Containers

Goal: package trust, config drift indicators, secrets exposure metadata, and container escape risks.

Read-only checks:

```bash
apt-key list 2>/dev/null
find /etc/apt -maxdepth 4 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
command -v docker podman containerd ctr crictl kubectl helm goss ansible-playbook 2>/dev/null
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null
docker inspect --format '{{.Name}} Privileged={{.HostConfig.Privileged}} User={{.Config.User}} NetworkMode={{.HostConfig.NetworkMode}} PidMode={{.HostConfig.PidMode}} CapAdd={{.HostConfig.CapAdd}} SecurityOpt={{.HostConfig.SecurityOpt}} Binds={{.HostConfig.Binds}}' $(docker ps -q 2>/dev/null) 2>/dev/null
docker info 2>/dev/null
ls -l /var/run/docker.sock 2>/dev/null
```

For secret exposure, do not dump values. Use metadata-only or redacted grep:

```bash
grep -RIlE '(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|PRIVATE_KEY|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY|api[_-]?key|token|password=)' /etc /home /opt /srv 2>/dev/null
```

Report matched file paths as potential exposure only. Do not print matching lines unless explicitly authorized and redacted.

Report availability of multi-layer tools:

- Lynis: report availability/version only unless a no-write/no-log audit command is confirmed.
- USG: report availability/version only unless a no-write/no-log audit command is confirmed; `--tailoring-file` only if the file already exists and execution is safe.
- Falco: status/config only unless already running; do not start it.
- ansible-lockdown/UBUNTU24-CIS: only report whether playbooks appear present. Do not run playbooks.
- Goss: only report availability and existing specs if discoverable. Do not create specs or run state-changing checks.

## EU Cybersecurity Compliance Overlay

This audit provides technical evidence mapping, not legal certification. The final report must include an "EU Compliance Evidence Map" covering NIS2, GDPR Art. 32, CRA, DORA, BSI IT-Grundschutz, and ISO 27001. For each framework, classify evidence as `checked`, `partial`, `blocked`, or `not applicable/unknown`, and explain why.

### GDPR Art. 32: Security Of Processing

Evidence goals: encryption, confidentiality, integrity, availability, resilience, breach detection, restore capability, and log retention.

Read-only checks:

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

Do not conclude personal-data pseudonymization from server config alone unless application log formats clearly prove it. If logs contain user IPs and no truncation/hashing is visible, mark as `risk/partial`, not a definitive legal breach unless the data context is known. Restore testing is `blocked` unless documented evidence exists or the user authorizes a restore test.

### NIS2 Article 21: Technical Control Evidence

Evidence goals: risk management, incident handling, continuity, supply chain, vulnerability handling, cryptography, access control, MFA, and asset management.

Map existing findings to NIS2 controls:

- Incident detection: auditd, SIEM/log shipping, fail2ban, monitoring agents.
- Business continuity: backup jobs, last successful backup evidence, restore-test evidence.
- Supply chain: APT repositories, package inventory, containers, SBOM availability.
- Vulnerability management: pending updates, unattended-upgrades, patch logs, Lynis/USG if present.
- Access control: sudo, SSH, MFA/PAM, login shells, privileged groups.
- Cryptography: TLS config, LUKS/dm-crypt, SSH algorithms.
- Asset inventory: hostname, role, services, ports, packages, containers, monitoring owner signals.

If organizational policies, risk register, incident response plan, or vendor register are not present on the host, mark those controls `blocked: requires external governance evidence`.

### CRA: Cyber Resilience Evidence

Evidence goals: security by default, vulnerability handling, SBOM/package inventory, no default credentials, exposed services, and support/update posture. CRA reporting obligations start 11 September 2026; main CRA obligations apply later, so report timeline-sensitive status without overstating certification.

Read-only checks:

```bash
dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\n' 2>/dev/null
apt list --upgradable 2>/dev/null
find /etc/apt -maxdepth 4 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
grep -RIlE '(password.*admin|password.*default|default.*password|admin:admin|changeme|ChangeMe|123456)' /etc /opt /srv /home 2>/dev/null
ss -tulpen
systemctl status unattended-upgrades --no-pager 2>/dev/null
find /etc /opt /srv -maxdepth 5 -iname '*vulnerab*' -o -iname '*security*policy*' -o -iname '*disclosure*' -o -iname '*sbom*' 2>/dev/null
```

Do not write SBOM files to the server. If an SBOM is needed, collect package inventory in the audit output or local notes only. Default-credential scans must report file paths only, not secret values.

### DORA: Digital Operational Resilience Evidence

Evidence goals: ICT asset register, incident classification, resilience testing evidence, concentration risk, monitoring, backup/restore, and operational ownership. Applies from 17 January 2025 to in-scope financial entities and ICT third-party service contexts.

Read-only checks:

```bash
find /etc /opt /srv /home -maxdepth 5 \( -iname '*asset*' -o -iname '*inventory*' -o -iname '*incident*' -o -iname '*ir-plan*' -o -iname '*continuity*' -o -iname '*bcp*' -o -iname '*drp*' -o -iname '*tlpt*' -o -iname '*restore*' -o -iname '*backup*test*' \) 2>/dev/null
hostnamectl
systemctl list-units --all --no-pager | egrep -i 'backup|monitor|prometheus|node_exporter|datadog|zabbix|wazuh|ossec|netdata|grafana|loki|promtail|vector|fluent|falco|tetragon' || true
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null
```

Do not infer DORA applicability from a server alone. Mark applicability as `unknown` unless the business context says the host serves financial entities. If multiple client workloads appear co-located, report potential concentration risk.

### BSI IT-Grundschutz Evidence

Evidence goals: SYS.1.3 Linux server controls, OPS.1.1.3 patch management, NET.1.1 segmentation, CON.3 data management.

Read-only checks:

```bash
cat /etc/issue /etc/issue.net 2>/dev/null
grep -RInE 'TMOUT|umask|PASS_MAX_DAYS|PASS_MIN_DAYS|pam_pwquality|pam_faillock|pam_tally|pam_google_authenticator|pam_u2f|pam_oath' /etc/login.defs /etc/profile /etc/profile.d /etc/pam.d 2>/dev/null
sysctl kernel.randomize_va_space kernel.yama.ptrace_scope fs.suid_dumpable kernel.core_pattern 2>/dev/null
sh -lc 'ulimit -c'
systemctl status systemd-coredump apport --no-pager 2>/dev/null
timedatectl status 2>/dev/null
chronyc tracking 2>/dev/null
ntpq -p 2>/dev/null
systemctl status chrony systemd-timesyncd ntp --no-pager 2>/dev/null
lsattr /var/log/auth.log /var/log/syslog /var/log/journal 2>/dev/null
ip -br addr
ip route
ss -tulpen
find /etc /opt /srv -maxdepth 5 \( -iname '*patch*' -o -iname '*change*log*' -o -iname '*runbook*' -o -iname '*grundschutz*' -o -iname '*segmentation*' -o -iname '*retention*' -o -iname '*destroy*' -o -iname '*wipe*' \) 2>/dev/null
```

Report login banner presence, core dump posture, ASLR, ptrace, SoD indicators, NTP validity for forensic timestamps, log immutability indicators, idle timeout, patch documentation, and segmentation evidence. Do not set `chattr +a`, `TMOUT`, banners, sysctls, or PAM settings.

### ISO 27001 Evidence Package

Map observed evidence to ISO-style control areas:

- Access control: privileged groups, SSH, MFA, sudoers, login shells.
- Cryptography: LUKS/dm-crypt, TLS protocols, SSH algorithms.
- Operations security: patching, logging, monitoring, backups, capacity, error logs.
- Asset management: host inventory, packages, services, ports, containers.
- Supplier/supply chain: APT sources, third-party repos, container images.
- Incident management: auditd/SIEM/log retention/IR plan signals.

Mark controls requiring ISMS documents, risk acceptance, policies, ownership records, or audit trails as `blocked: requires governance evidence outside host`.

## Cross-Host Drift

For two or more hosts, compare:

- OS, kernel, uptime, timezone, virtualization.
- Running/enabled/failed services and timers.
- Listening ports and firewall rules.
- Users with login shells, sudo/docker/lxd/journal access.
- SSH effective config.
- Sysctl hardening values.
- AppArmor/SELinux/auditd status.
- Package repositories, installed packages, pending updates.
- Docker/container posture.
- Backup and monitoring signals.
- Disk layout, mounts, large directories, cleanup candidates.
- Error patterns in recent logs.

Classify drift as `expected`, `suspicious`, `risky`, or `unknown`. Explain why.

## Evidence Standard

Every finding must include:

- Host.
- Layer/category.
- Severity: `critical`, `high`, `medium`, `low`, or `info`.
- Evidence summarized from command output, with secrets redacted.
- Impact.
- Recommendation.
- Action class: `read-only follow-up`, `safe reversible change`, or `destructive/state-changing approval required`.

## Final Report Required Structure

The final answer must include:

- Executive summary for each host and overall MSP readiness.
- Coverage matrix by host and layer, including blocked/partial reasons.
- Top findings ordered by severity.
- Drift summary between hosts.
- Security posture by layer: eBPF/runtime, kernel/privilege, identity/SSH, network, maintenance, operations, supply chain/containers.
- Cleanup candidates with estimated size where available.
- Backup, monitoring, patching, and documentation gaps.
- Unknowns and blind spots.
- Next steps split into read-only follow-up, safe reversible changes, and state-changing/destructive actions requiring explicit approval.

Never imply remediation was performed. The audit only observes and reports.
