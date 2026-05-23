# Changelog

All notable changes to this project are documented here.

This project follows a pragmatic versioning model while the skill stabilizes:

- `0.x`: active design iteration.
- `1.x`: stable public skill interface and report contract.

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
- MSP readiness, drift, security posture, and operations coverage.
