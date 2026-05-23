#!/usr/bin/env bash
set -u

DEPTH="standard"
WITH_SUDO=0

usage() {
  cat <<'USAGE'
Usage: audit-core.sh [--depth quick|standard|deep] [--with-sudo]

Strict read-only audit collector.

Options:
  --depth quick      Preflight and basic health only.
  --depth standard   Default baseline collection.
  --depth deep       Standard plus deeper local checks; implies --with-sudo.
  --with-sudo        Run additional sudo -n read-only checks if available.
  -h, --help         Show this help.

Notes:
  sudo checks use sudo -n and never prompt for a password.
  This script intentionally does not use set -e because failed checks are evidence.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --depth)
      shift
      DEPTH="${1:-}"
      ;;
    --depth=*)
      DEPTH="${1#*=}"
      ;;
    --with-sudo)
      WITH_SUDO=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

case "$DEPTH" in
  quick|standard|deep) ;;
  *)
    printf 'Invalid --depth: %s\n' "$DEPTH" >&2
    usage >&2
    exit 2
    ;;
esac

if [ "$DEPTH" = "deep" ]; then
  WITH_SUDO=1
fi

section() {
  printf '\n===== %s =====\n' "$1"
}

run() {
  "$@" 2>/dev/null || true
}

sudo_run() {
  if [ "$WITH_SUDO" -eq 1 ] && command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo -n "$@" 2>/dev/null | redact || true
  else
    printf 'blocked: sudo read-only check unavailable or not requested:'
    printf ' %s' "$@"
    printf '\n'
  fi
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
printf 'audit_depth=%s\n' "$DEPTH"
printf 'with_sudo=%s\n' "$WITH_SUDO"
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
sh -lc 'ulimit -c' 2>/dev/null || true

if [ "$DEPTH" = "quick" ]; then
  section QUICK_HEALTH
  systemctl --failed --no-pager
  df -hT
  free -h
  ss -tulpen
  exit 0
fi

section RUNTIME_EBPF
command -v falco tetragon cilium bpftrace bpftool 2>/dev/null || true
systemctl status falco tetragon cilium-agent --no-pager 2>/dev/null | redact || true
bpftool prog list 2>/dev/null | redact || true

section KERNEL_CIS
find / -xdev -perm /6000 -type f -ls 2>/dev/null
sysctl net.ipv4.tcp_syncookies kernel.randomize_va_space net.ipv4.ip_forward net.ipv6.conf.all.forwarding kernel.dmesg_restrict kernel.kptr_restrict kernel.yama.ptrace_scope fs.suid_dumpable kernel.core_pattern 2>/dev/null
systemctl --failed --no-pager
systemctl status auditd apparmor --no-pager 2>/dev/null | redact || true
aa-status 2>/dev/null | redact || true
auditctl -l 2>/dev/null | redact || true
command -v aide rkhunter debsums lynis usg ssh-audit 2>/dev/null || true

section IDENTITY_SSH
grep -vE ':(/usr/sbin/nologin|/sbin/nologin|/bin/false)$' /etc/passwd 2>/dev/null
getent group sudo adm docker lxd systemd-journal 2>/dev/null || true
grep -nE '^[[:space:]]*(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AuthorizedKeysFile|KexAlgorithms|HostKeyAlgorithms|PubkeyAcceptedAlgorithms|AuthenticationMethods|PermitEmptyPasswords|MaxAuthTries)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null
last -n 20
lastlog -t 90 2>/dev/null || true
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
chronyc tracking 2>/dev/null || ntpq -p 2>/dev/null || true

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
docker ps -q 2>/dev/null | while read -r cid; do
  docker inspect --format 'container={{.Name}} image={{.Config.Image}} user={{.Config.User}} privileged={{.HostConfig.Privileged}} cap_add={{json .HostConfig.CapAdd}} security_opt={{json .HostConfig.SecurityOpt}} network={{.HostConfig.NetworkMode}} pid={{.HostConfig.PidMode}} binds={{json .HostConfig.Binds}}' "$cid" 2>/dev/null | redact || true
done
ls -l /var/run/docker.sock 2>/dev/null || true

section EU_EVIDENCE
lsblk -f
for d in /dev/mapper/*; do
  test -e "$d" && cryptsetup status "$(basename "$d")" 2>/dev/null | redact || true
done
journalctl --disk-usage 2>/dev/null || true
journalctl --list-boots --no-pager 2>/dev/null || true
cat /etc/issue /etc/issue.net 2>/dev/null || true
grep -RInE 'TMOUT|PASS_MAX_DAYS|PASS_MIN_DAYS|pam_pwquality|pam_faillock|pam_google_authenticator|pam_u2f|pam_oath' /etc/login.defs /etc/profile /etc/profile.d /etc/pam.d 2>/dev/null || true

section SUDO_READONLY
if [ "$WITH_SUDO" -eq 1 ]; then
  sudo_run nft list ruleset
  sudo_run iptables -S
  sudo_run ip6tables -S
  sudo_run ufw status verbose
  sudo_run auditctl -l
  sudo_run auditctl -s
  sudo_run aa-status
  sudo_run bpftool prog list
  sudo_run sshd -T
  sudo_run fail2ban-client status
  for jail in $(sudo -n fail2ban-client status 2>/dev/null | sed -n 's/.*Jail list:[[:space:]]*//p' | tr ',' ' '); do
    sudo_run fail2ban-client status "$jail"
  done
  sudo -n docker ps -q 2>/dev/null | while read -r cid; do
    sudo -n docker inspect --format 'container={{.Name}} image={{.Config.Image}} user={{.Config.User}} privileged={{.HostConfig.Privileged}} cap_add={{json .HostConfig.CapAdd}} cap_drop={{json .HostConfig.CapDrop}} security_opt={{json .HostConfig.SecurityOpt}} network={{.HostConfig.NetworkMode}} pid={{.HostConfig.PidMode}} ipc={{.HostConfig.IpcMode}} readonly_rootfs={{.HostConfig.ReadonlyRootfs}} binds={{json .HostConfig.Binds}} mounts={{json .Mounts}}' "$cid" 2>/dev/null | redact || true
  done
  sudo -n docker image ls --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.CreatedSince}} {{.Size}}' 2>/dev/null | redact || true
  for d in /dev/mapper/*; do
    test -e "$d" && sudo_run cryptsetup status "$(basename "$d")"
  done
  cut -f1 -d: /etc/passwd 2>/dev/null | while read -r user; do
    printf 'user_crontab=%s\n' "$user"
    sudo -n crontab -u "$user" -l 2>/dev/null | redact || true
  done
else
  printf 'skipped: run with --with-sudo or --depth deep to collect sudo-only read evidence\n'
fi
