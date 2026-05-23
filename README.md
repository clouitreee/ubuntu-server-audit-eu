# ubuntu-server-audit-eu

```text
+------------------------------------------------------------+
| ubuntu-server-audit-eu                                     |
| Deep read-only Ubuntu/Linux audit for MSP onboarding,       |
| security posture, drift, and EU compliance evidence.        |
+------------------------------------------------------------+
```

`ubuntu-server-audit-eu` is an Agent/Codex skill for strict read-only SSH inspections of Ubuntu/Linux servers. It is designed for MSP readiness, operational disorder review, security hardening evidence, cross-host drift, and EU cybersecurity compliance mapping.

The skill does not remediate, install tools, clean files, restart services, update packages, or write audit artifacts to the target server. If a tool or baseline is missing, the report must say `partial` or `blocked` and explain why.

## What It Covers

- Ubuntu Server 2026 technical framework: eBPF/runtime, CIS-style hardening, identity/SSH, network exposure, system maintenance, operations, supply chain, containers, and drift.
- EU compliance evidence overlay: NIS2 Art. 21, GDPR Art. 32, CRA, DORA, BSI IT-Grundschutz, and ISO 27001-style evidence areas.
- MSP onboarding posture: asset inventory, patching, backups, monitoring, logs, access control, exposed services, documentation gaps, and unknowns.
- Read-only discipline: no package installs, no service changes, no file edits, no cleanup, no secret disclosure.

## Install

Copy the skill folder into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
cp -R skills/ubuntu-server-audit-eu ~/.codex/skills/
```

Then restart Codex so the skill metadata is loaded.

## Use

Ask Codex to inspect one or more hosts in read-only mode:

```text
Use ubuntu-server-audit-eu to audit ssh core and ssh edge in strict read-only mode.
```

Expected output includes:

- Executive summary for each host.
- Coverage matrix with `checked`, `partial`, `blocked`, or `not checked`.
- Ubuntu Server 2026 Framework section with layers 0-6.
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
- Restore tests, remediation, package updates, firewall changes, and service restarts require explicit authorization outside this skill.

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
