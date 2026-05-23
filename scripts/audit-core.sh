#!/usr/bin/env bash
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

redact() {
  sed -E \
    -e 's/--token([=[:space:]])[^[:space:]]+/--token\1[REDACTED]/gI' \
    -e 's/--api-?key([=[:space:]])[^[:space:]]+/--api-key\1[REDACTED]/gI' \
    -e 's/--password([=[:space:]])[^[:space:]]+/--password\1[REDACTED]/gI' \
    -e 's/(Authorization:[[:space:]]*)(Bearer|Basic)[[:space:]]+[^[:space:]]+/\1\2 [REDACTED]/gI' \
    -e 's/(X-Auth-Key:[[:space:]]*)[^[:space:]]+/\1[REDACTED]/gI' \
    -e 's/(X-Auth-Email:[[:space:]]*)[^[:space:]]+/\1[REDACTED]/gI' \
    -e 's#(://[^:/[:space:]]+:)[^@/[:space:]]+@#\1[REDACTED]@#g' \
    -e 's/([A-Z0-9_]*(TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|AUTH_KEY|PRIVATE_KEY|ACCESS_KEY|WEBHOOK)[A-Z0-9_]*=)[^[:space:]]+/\1***/gI'
}

section PREFLIGHT
hostnamectl 2>/dev/null
uname -a
date
timedatectl status 2>/dev/null
uptime
whoami
id
pwd
lsb_release -a 2>/dev/null || cat /etc/os-release 2>/dev/null
systemd-detect-virt 2>/dev/null || true

section RUNTIME_EBPF
command -v falco tetragon cilium bpftrace bpftool 2>/dev/null || true
systemctl status falco tetragon cilium-agent --no-pager 2>/dev/null || true
bpftool prog list 2>/dev/null || true

section KERNEL_CIS
find / -xdev -perm /6000 -type f -ls 2>/dev/null
sysctl net.ipv4.tcp_syncookies kernel.randomize_va_space net.ipv4.ip_forward net.ipv6.conf.all.forwarding kernel.dmesg_restrict kernel.kptr_restrict kernel.yama.ptrace_scope fs.suid_dumpable kernel.core_pattern 2>/dev/null
systemctl --failed --no-pager
systemctl status auditd apparmor --no-pager 2>/dev/null || true
command -v aide rkhunter debsums lynis usg ssh-audit 2>/dev/null || true

section IDENTITY_SSH
grep -vE ':(/usr/sbin/nologin|/sbin/nologin|/bin/false)$' /etc/passwd 2>/dev/null
getent group sudo adm docker lxd systemd-journal 2>/dev/null || true
grep -nE '^[[:space:]]*(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AuthorizedKeysFile|KexAlgorithms|HostKeyAlgorithms|PubkeyAcceptedAlgorithms|AuthenticationMethods|PermitEmptyPasswords|MaxAuthTries)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null
last -n 20
who
w
find /home /root -maxdepth 3 -name authorized_keys -type f -printf '%p %u %g %m %TY-%Tm-%Td %TH:%TM\n' 2>/dev/null

section NETWORK
ip -br addr
ip route
ss -tulpen
ss -tnp state established 2>/dev/null || true
systemctl status fail2ban --no-pager 2>/dev/null | redact || true
resolvectl status 2>/dev/null || cat /etc/resolv.conf 2>/dev/null

section OPERATIONS
df -hT
df -ih
findmnt
free -h
ps aux --sort=-%mem | redact | head -30
journalctl -p err -n 50 --no-pager 2>/dev/null | redact
du -xhd1 / 2>/dev/null | sort -h
du -xhd1 /var 2>/dev/null | sort -h
du -xhd1 /home 2>/dev/null | sort -h
find /var/log -xdev -type f -size +100M -printf '%s %p\n' 2>/dev/null | sort -n
find /tmp /var/tmp -xdev -mindepth 1 -maxdepth 2 -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -100
systemctl list-timers --all --no-pager | egrep -i 'backup|borg|restic|rsync|duplicity|snapshot|dump' || true

section SUPPLY_CHAIN
apt list --upgradable 2>/dev/null || true
find /etc/apt -maxdepth 4 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
command -v docker podman containerd ctr crictl kubectl helm goss ansible-playbook 2>/dev/null || true
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
ls -l /var/run/docker.sock 2>/dev/null || true

section EU_EVIDENCE
lsblk -f
journalctl --disk-usage 2>/dev/null || true
journalctl --list-boots --no-pager 2>/dev/null || true
cat /etc/issue /etc/issue.net 2>/dev/null || true
grep -RInE 'TMOUT|PASS_MAX_DAYS|PASS_MIN_DAYS|pam_pwquality|pam_faillock|pam_google_authenticator|pam_u2f|pam_oath' /etc/login.defs /etc/profile /etc/profile.d /etc/pam.d 2>/dev/null || true
