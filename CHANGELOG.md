# Changelog

All notable changes to this project are documented here.

This project follows a pragmatic versioning model while the skill stabilizes:

- `0.x`: active design iteration.
- `1.x`: stable public skill interface and report contract.

## [0.5.0] - 2026-05-23

### Added

- `references/L9-secrets-and-persistence-drift.md` for metadata-only secret path discovery, unpackaged systemd unit drift, SSH authorized key drift, known-hosts external trust indicators, DORA asset register discovery, ISO 27001:2022 Annex A mapping, and ENISA/NIS2 mapping guidance.
- `AGENTS.md` so agentic CLIs can discover the repository behavior when used directly in a workspace.
- GitHub Actions ShellCheck workflow for Bash script validation.
- `audit-core.sh` collection for likely secret file metadata, unpackaged systemd units, recent authorized keys, hashed external known-host indicators, and asset/inventory/CMDB evidence paths.

## [0.4.0] - 2026-05-23

### Added

- `audit-core.sh --depth quick|standard|deep` for tiered audit scope.
- `audit-core.sh --with-sudo` for explicit sudo-only read checks using `sudo -n`.
- Additional read-only evidence for AppArmor, audit rules, time sync, LUKS mapper status, lastlog, core dump limits, firewall rules, effective SSH config, Fail2Ban, and Docker metadata.
- `references/L8-container-runtime.md` for container runtime evidence and security findings.

### Documented

- `set -e` is intentionally avoided so blocked or failed checks remain visible evidence instead of aborting the audit.
- Roadmap for structured output, temporal drift comparison, richer report generation, and local asset labels.

## [0.3.0] - 2026-05-23

### Added

- `references/L7-agent-safety-evolution.md` for prompt-injection handling, memory-poisoning guardrails, tool-output distrust, and controlled skill improvement.
- README guidance and references for agent safety, OWASP LLM risks, memory guardrails, and human-reviewed improvement candidates.
- Final report requirement for suspicious-instruction observations and sanitized skill improvement candidates.

## [0.2.1] - 2026-05-23

### Added

- Explicit secret-safe audit handling rules for process lists, systemd output, Docker metadata, logs, `.env` files, vaults, and remote command output.
- Stronger automatic redaction in `scripts/audit-core.sh` for token, password, API key, auth header, credential URL, and env-var patterns.

## [0.2.0] - 2026-05-23

### Added

- Progressive disclosure layout with root `SKILL.md`, layer references, and read-only scripts.
- Multi-agent CLI positioning for Codex, Claude Code, Gemini CLI, opencode, Cursor-style agents, and similar tools.
- `scripts/audit-core.sh` for fast read-only baseline collection.
- `scripts/generate-report.sh` for local summary generation from one or more captured audit outputs.
- README badges and repository layout documentation.

### Changed

- Moved the skill entry point from `skills/ubuntu-server-audit-eu/SKILL.md` to root `SKILL.md`.
- Split deep technical checks into `references/L1-L6`.

## [0.1.0] - 2026-05-23

### Added

- Initial public skill for read-only Ubuntu/Linux server audits.
- EU cybersecurity evidence mapping for NIS2, GDPR Art. 32, CRA, DORA, BSI IT-Grundschutz, and ISO 27001-style evidence areas.
- Server readiness, drift, security posture, and operations coverage.
