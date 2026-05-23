#!/usr/bin/env bash
set -u

if [ "$#" -lt 1 ]; then
  printf 'Usage: %s <audit-output> [audit-output...]\n\n' "$0" >&2
  printf 'Generate a local summary from one or more captured audit outputs.\n' >&2
  printf 'This script does not SSH and does not modify servers.\n\n' >&2
  printf 'Examples:\n' >&2
  printf '  %s core-audit.txt\n' "$0" >&2
  printf '  %s core-audit.txt edge-audit.txt dmz-audit.txt\n' "$0" >&2
  exit 2
fi

printf '# Ubuntu Server Audit EU Summary\n\n'
printf 'Generated from local captured outputs. This script does not SSH and does not modify servers.\n\n'

for file in "$@"; do
  if [ ! -f "$file" ]; then
    printf '## %s\n\nMissing file.\n\n' "$file"
    continue
  fi

  host="$(awk '/Static hostname:/ {print $3; exit}' "$file")"
  [ -n "$host" ] || host="$(basename "$file")"

  printf '## %s\n\n' "$host"
  printf '%s\n' "- Sections captured: $(grep -c '^===== ' "$file" 2>/dev/null || :)"
  printf '%s\n' "- Failed units marker: $(grep -m1 -E '0 loaded units listed|failed' "$file" | sed 's/^[[:space:]]*//')"
  printf '%s\n' "- Upgradable packages: $(grep -c '\[upgradable from:' "$file" 2>/dev/null || :)"
  printf '%s\n' "- SUID/SGID entries: $(awk '/KERNEL_CIS|L1_KERNEL_PRIV_CIS/{flag=1;next}/IDENTITY_SSH|L2_IDENTITY_SSH/{flag=0}flag && / -r..s| -rwxr-s| -rws/{c++}END{print c+0}' "$file")"
  printf '%s\n' "- Large log files >100M: $(grep -Ec '^[0-9]+ /var/log' "$file" 2>/dev/null || :)"
  printf '%s\n\n' "- Possible secret-bearing paths: $(grep -Ec '^/.*(\\.env|token|password|PRIVATE_KEY|api[_-]?key)' "$file" 2>/dev/null || :)"
done
