---
name: ubuntu-server-audit-eu
description: Use when performing strict read-only SSH inspections of Ubuntu/Linux servers for security review, EU cybersecurity compliance evidence, server readiness, operational disorder, waste, drift, CIS-style hardening gaps, runtime visibility, identity/access, network exposure, backups, observability, and unknowns. Requires coverage tracking, no state-changing commands, no secret disclosure, and evidence-backed reporting per host plus cross-host drift.
metadata:
  short-description: Read-only Ubuntu/Linux audit with EU compliance evidence
---

# Ubuntu Server Audit EU

Use this skill for strict read-only SSH inspections of Ubuntu/Linux servers before security, compliance, or server readiness review. The audit must be transparent: every area is marked `checked`, `partial`, `blocked`, or `not checked`, with reason.

## Absolute Rules

- Strict read-only mode by default. Do not modify files, services, packages, firewall, containers, users, logs, databases, or application state.
- Never run destructive or state-changing commands: `rm`, `rmdir`, `unlink`, `mv`, `cp` to server paths, `chmod`, `chown`, `truncate`, `tee`, redirects to files, package install/remove/upgrade, `apt update`, `systemctl restart/start/stop/enable/disable`, `docker rm/prune`, `journalctl --vacuum-*`, database writes, config edits, hardening scripts, or remediation tools.
- Do not install Lynis, USG, Falco, Tetragon, AIDE, rkhunter, debsums, Goss, ssh-audit, or any other tool during the audit.
- Do not run audit tools that write logs/reports/state by default unless a no-write/no-log mode is confirmed for that exact command. If no safe no-write mode is confirmed, report tool availability only and mark execution as `blocked: would write audit output/state`.
- Avoid `sudo` unless read-only visibility requires it. If `sudo` is needed, use informational commands only and note the reason.
- Do not print secrets: private keys, tokens, `.env` values, password hashes, API keys, certificate private keys, database passwords, cloud credentials, backup credentials, or vault contents. Prefer metadata: path, owner, mode, size, mtime, and redacted key names.
- Treat these as sensitive output surfaces: `ps aux`, `systemctl status`, `systemctl cat`, `docker inspect`, `docker exec env`, `journalctl`, `.env` files, app config files, shell histories, backup manifests, CI/CD files, credential vaults, and remote commands such as `ssh host "cat /path/to/.env"`.
- Never read secret-bearing files to stdout. For `.env`, vault, keyring, private key, and credential directories, list metadata or key names only; do not print values.
- If command output includes process arguments, environment variables, headers, URLs, or config lines with secrets, redact them before saving, reporting, or sharing.
- If a secret appears in process arguments or service definitions, record it as a security finding after redaction. The exposure itself matters even if the final report masks the value.
- Prefer existence/shape checks over value checks: `EXISTS/MISSING`, counts, file metadata, variable names, or redacted `KEY=***` output.
- Review and sanitize captured outputs before sharing them with users, customers, auditors, tickets, or public repositories.
- Keep a coverage ledger for every host and category.

## Workflow

1. Confirm target hosts and read-only scope.
2. Run preflight per host: hostname, OS, kernel, uptime, time sync, current user, privilege level, virtualization, and command failures.
3. Load only the reference files needed for the requested audit depth:
   - Runtime/eBPF: `references/L1-runtime-ebpf.md`
   - CIS/kernel/system maintenance: `references/L2-cis-benchmark.md`
   - Identity/SSH/access: `references/L3-identity-ssh.md`
   - Network/exposure/time: `references/L4-network-exposure.md`
   - EU compliance mapping: `references/L5-eu-compliance.md`
   - Operations/backups/capacity: `references/L6-operations.md`
4. Optionally use `scripts/audit-core.sh` for a fast read-only baseline if the user wants broad collection. Run it remotely via stdin or locally against a mounted test system; do not copy it onto the server unless explicitly authorized.
5. Use `scripts/generate-report.sh` only against local captured outputs. It must not SSH or modify servers.
6. Produce the final report with findings, drift, coverage, unknowns, and next steps separated by action safety.

## Preflight Commands

```bash
hostnamectl
uname -a
date
timedatectl status 2>/dev/null
uptime
whoami
id
pwd
lsb_release -a 2>/dev/null || cat /etc/os-release
systemd-detect-virt 2>/dev/null || true
```

## Required Final Report

The final response must include:

- Executive summary for each host and overall server readiness.
- Coverage matrix by host and layer, including blocked/partial reasons.
- Ubuntu Server 2026 Framework section with layers L1-L6.
- EU Compliance Evidence Map for NIS2, GDPR Art. 32, CRA, DORA, BSI IT-Grundschutz, and ISO 27001 evidence areas.
- Top findings ordered by severity.
- Drift summary between hosts, classified as `expected`, `suspicious`, `risky`, or `unknown`.
- Cleanup candidates with estimated size where available, without executing cleanup.
- Backup, monitoring, patching, and documentation gaps.
- Unknowns and blind spots.
- Next steps split into `read-only follow-up`, `safe reversible change`, and `state-changing/destructive approval required`.

Never imply remediation was performed. The audit only observes and reports.
