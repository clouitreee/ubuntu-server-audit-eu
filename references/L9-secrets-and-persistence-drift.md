# L9 Secrets And Persistence Drift

Use this layer for read-only discovery of likely secret files, unpackaged persistence points, and SSH trust drift. It must never print secret file contents.

## Secrets On Disk By Name

Only collect metadata: path, owner, group, mode, size, and mtime. Do not run `cat`, `head`, `tail`, `grep`, `strings`, or content scanners against secret-bearing files unless the user explicitly authorizes a separate secret review.

```bash
find /etc /home /root /var/www /opt /srv -xdev -type f \
  \( -name '*.env' -o -name '.env*' -o -name '*.pem' -o -name '*.key' \
     -o -name 'id_rsa' -o -name 'id_ed25519' -o -name 'credentials' \
     -o -name 'credentials.json' -o -name 'secrets.yml' -o -name 'secrets.yaml' \
     -o -name 'vault*' -o -name '*.tfvars' -o -name '*.kubeconfig' \) \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p %u %g %m\n' 2>/dev/null
```

Compliance relevance: GDPR Art. 32 confidentiality/integrity, NIS2 Art. 21 supply-chain/access-control measures, CRA vulnerability handling and secure-by-default evidence.

## Systemd Unit Drift

Manual or unpackaged systemd units can be legitimate, but they are also common persistence points. Detect units that do not map to a package.

```bash
find /etc/systemd /usr/local/lib/systemd /usr/lib/systemd /lib/systemd -type f \
  \( -name '*.service' -o -name '*.timer' -o -name '*.socket' -o -name '*.path' \) 2>/dev/null \
| while read -r unit; do
    dpkg -S "$unit" >/dev/null 2>&1 || printf 'UNPACKAGED %s\n' "$unit"
  done
```

Do not print unit contents by default. If unit contents are needed, first decide whether `systemctl cat` might expose secrets in `Environment=` or command arguments; redact before reporting.

## SSH Authorized Keys Drift

Collect metadata for authorized keys and flag recent changes. Do not print key material.

```bash
find /home /root -name authorized_keys -type f \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p %u %g %m\n' 2>/dev/null
find /home /root -name authorized_keys -type f -mtime -30 \
  -printf 'RECENT_AUTHORIZED_KEYS %TY-%Tm-%Td %TH:%TM %s %p %u %g %m\n' 2>/dev/null
```

If the baseline file `/etc/passwd` is used as a rough comparison point, document that it is only a heuristic and not proof of unauthorized access.

## SSH Known Hosts External Trust

Known-hosts data can expose external relationships. Prefer counts and hashed indicators instead of raw hostnames/IPs.

```bash
grep -rh "" /home/*/.ssh/known_hosts /root/.ssh/known_hosts 2>/dev/null \
| awk '{print $1}' \
| grep -vE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|localhost|\[)' \
| sed 's/,.*//' \
| sort -u \
| while read -r host; do
    printf '%s\n' "$host" | sha256sum | awk '{print "KNOWN_HOST_EXTERNAL_SHA256_12 " substr($1,1,12)}'
  done
```

Report counts and partial hashes only unless the user explicitly asks for raw external known-host entries.

## DORA ICT Asset Register Discovery

Look for host-visible asset inventory, CMDB, incident, continuity, and restore evidence. Do not treat absence on the host as absence in the organization.

```bash
find /etc /opt /srv /root -maxdepth 5 \
  \( -iname 'asset*' -o -iname '*inventory*' -o -iname '*cmdb*' \
     -o -iname '*incident*' -o -iname '*continuity*' -o -iname '*restore*' \) \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p %u %g %m\n' 2>/dev/null
```

## ISO 27001:2022 Annex A Mapping

Map findings to evidence areas without claiming certification:

- A.8.8 Technical vulnerability management: patch posture, upgradable packages, vulnerability process evidence.
- A.8.9 Configuration management: sysctl, SSH config, systemd drift, package ownership, container runtime posture.
- A.8.12 Data leakage prevention: secret-bearing paths, exposed process arguments, logs with sensitive values.
- A.8.16 Monitoring activities: auditd, journald, syslog, SIEM/agent status, Fail2Ban.
- A.8.20 Network security: listening ports, firewall rules, segmentation evidence, WireGuard/VPN exposure.
- A.8.24 Use of cryptography: LUKS/dm-crypt, TLS config, SSH key algorithms, certificate posture.

## ENISA/NIS2 Technical Guidance Mapping

When mapping to ENISA or NIS2 guidance, keep the report evidence-based:

- Distinguish technical host evidence from governance evidence.
- Mark governance artifacts as `blocked` or `not host-visible` unless files are present.
- Avoid implying legal compliance from a server-only audit.
