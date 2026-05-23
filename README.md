# ubuntu-server-audit-eu

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.2.1-blue.svg)](CHANGELOG.md)
[![Read-only](https://img.shields.io/badge/mode-read--only-brightgreen.svg)](SKILL.md)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-orange.svg)](https://ubuntu.com/server)
[![Agent Skill](https://img.shields.io/badge/agent--skill-Codex%20%7C%20Claude%20%7C%20Gemini%20%7C%20opencode-black.svg)](SKILL.md)

```text
+------------------------------------------------------------+
| ubuntu-server-audit-eu                                     |
| Deep read-only Ubuntu/Linux audit for server security,      |
| security posture, drift, and EU compliance evidence.        |
+------------------------------------------------------------+
```

`ubuntu-server-audit-eu` is a portable agent skill for strict read-only SSH inspections of Ubuntu/Linux servers. It is designed for server security review, operational disorder analysis, hardening evidence, cross-host drift, and EU cybersecurity compliance mapping.

It is intentionally plain Markdown + shell so it can be used by Codex, Claude Code, Gemini CLI, opencode, Cursor-style agents, and other agentic CLIs that understand repository-local instructions.

The skill does not remediate, install tools, clean files, restart services, update packages, or write audit artifacts to the target server. If a tool or baseline is missing, the report must say `partial` or `blocked` and explain why.

Current version: `0.2.1`. See [CHANGELOG.md](CHANGELOG.md) for release history.

## What It Covers

- Ubuntu Server 2026 technical framework: eBPF/runtime, CIS-style hardening, identity/SSH, network exposure, system maintenance, operations, supply chain, containers, and drift.
- EU compliance evidence overlay: NIS2 Art. 21, GDPR Art. 32, CRA, DORA, BSI IT-Grundschutz, and ISO 27001-style evidence areas.
- Server readiness posture: asset inventory, patching, backups, monitoring, logs, access control, exposed services, documentation gaps, and unknowns.
- Read-only discipline: no package installs, no service changes, no file edits, no cleanup, no secret disclosure.

## Repository Layout

```text
ubuntu-server-audit-eu/
├── SKILL.md
├── README.md
├── CHANGELOG.md
├── references/
│   ├── L1-runtime-ebpf.md
│   ├── L2-cis-benchmark.md
│   ├── L3-identity-ssh.md
│   ├── L4-network-exposure.md
│   ├── L5-eu-compliance.md
│   └── L6-operations.md
└── scripts/
    ├── audit-core.sh
    └── generate-report.sh
```

The root `SKILL.md` is the entry point. The `references/` files keep deep checks out of context until needed. The scripts are read-only helpers; they do not install packages, restart services, edit files, clean logs, or remediate.

## Install For Agent CLIs

### Codex

```bash
mkdir -p ~/.codex/skills
cp -R ubuntu-server-audit-eu ~/.codex/skills/
```

Restart Codex so the skill metadata is loaded.

### Claude Code

Use this repo as a project skill or copy it into your Claude skills directory if your setup supports local skills. The root `SKILL.md` follows the standard skill frontmatter pattern and keeps detailed references in `references/`.

### Gemini CLI, opencode, Cursor, And Other Agents

Keep the repository in the workspace and tell the agent:

```text
Use the local ubuntu-server-audit-eu skill. Read SKILL.md first, then load only the reference files needed for the requested audit layers.
```

The skill does not depend on Codex-specific APIs.

## Use

Ask Codex to inspect one or more hosts in read-only mode:

```text
Use ubuntu-server-audit-eu to audit ssh core and ssh edge in strict read-only mode.
```

For a fast baseline collection, an agent may run the script over SSH without copying it to the server:

```bash
ssh core 'bash -s' < scripts/audit-core.sh > core-audit.txt
ssh edge 'bash -s' < scripts/audit-core.sh > edge-audit.txt
scripts/generate-report.sh core-audit.txt edge-audit.txt
```

`generate-report.sh` accepts one or more captured audit outputs:

```bash
scripts/generate-report.sh core-audit.txt
scripts/generate-report.sh core-audit.txt edge-audit.txt dmz-audit.txt
```

Review and redact local outputs before sharing. Process lists, service definitions, container metadata, logs, shell histories, and `.env`-style files can expose tokens, passwords, API keys, headers, database URLs, or cloud credentials.

Secret-safe handling rules:

- Do not print secret-bearing file contents. List path, owner, mode, size, mtime, key names, or `EXISTS/MISSING` instead.
- Redact values before saving or sharing: use `KEY=***`, `--token [REDACTED]`, `Authorization: [REDACTED]`, and similar patterns.
- Treat secrets in process arguments or systemd unit definitions as findings after redaction.
- Do not publish raw audit outputs to GitHub, tickets, customer portals, or auditor evidence rooms until they have been reviewed.

Expected output includes:

- Executive summary for each host.
- Coverage matrix with `checked`, `partial`, `blocked`, or `not checked`.
- Ubuntu Server 2026 Framework section with layers L1-L6.
- EU Compliance Evidence Map.
- Top findings ordered by severity.
- Cross-host drift summary.
- Cleanup candidates without executing cleanup.
- Read-only follow-ups, safe reversible recommendations, and state-changing actions requiring explicit approval.

## Safety Model

This skill is intentionally conservative:

- Tools such as Lynis, USG, rkhunter, Falco, Goss, and ansible-lockdown are not installed during the audit.
- Tools that write logs/reports/state are not executed unless a no-write/no-log mode is confirmed.
- Secrets are not printed. Secret scans report file paths only.
- `ps`, `systemctl`, `docker`, `journalctl`, and config/log reads are treated as secret-risk surfaces and must be redacted before reporting.
- Restore tests, remediation, package updates, firewall changes, and service restarts require explicit authorization outside this skill.

## Versioning

The project uses pragmatic pre-1.0 versioning while the public skill interface stabilizes:

- `0.x`: active design iteration, report contract may improve.
- `1.x`: stable public skill interface and report contract.
- Patch releases such as `0.2.1` are for safety, documentation, and script hardening that preserve the existing workflow.

## References

Publication and skill directories:

- VoltAgent awesome-agent-skills: https://github.com/VoltAgent/awesome-agent-skills
- Composio awesome-codex-skills: https://github.com/ComposioHQ/awesome-codex-skills
- Composio awesome-claude-skills: https://github.com/ComposioHQ/awesome-claude-skills
- Awesome Skills directory/spec: https://www.awesomeskills.dev/en
- Claude Agent Skills docs: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

Legal and compliance references:

- NIS2 Directive: https://eur-lex.europa.eu/eli/dir/2022/2555/oj
- GDPR: https://eur-lex.europa.eu/eli/reg/2016/679/oj
- Cyber Resilience Act summary: https://digital-strategy.ec.europa.eu/en/policies/cra-summary
- DORA: https://eur-lex.europa.eu/eli/reg/2022/2554/oj
- BSI IT-Grundschutz: https://www.bsi.bund.de/EN/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/IT-Grundschutz/it-grundschutz_node.html
- Canonical Ubuntu Security Guide: https://ubuntu.com/security/certifications/docs/usg
- CIS Ubuntu Linux 24.04 benchmark audit files: https://www.tenable.com/audits/CIS_Ubuntu_Linux_24.04_LTS_v1.0.0_L1_Server

Tools referenced by the skill:

- Lynis: https://github.com/CISOfy/lynis
- ssh-audit: https://github.com/jtesta/ssh-audit
- ansible-lockdown UBUNTU24-CIS: https://github.com/ansible-lockdown/UBUNTU24-CIS
- Falco: https://falco.org

## License

MIT
