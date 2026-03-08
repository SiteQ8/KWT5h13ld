# Changelog

All notable changes to **KWT5H13LD** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] — 2026-03-08

### Added
- **Modern Web GUI v2.0** — Complete redesign with dark cybersecurity aesthetic
  - Secure login page with authentication (demo: `admin` / `password`)
  - Interactive security dashboard with real-time scan results
  - Threat level gauge with security score visualization
  - Activity timeline with live event stream
  - Tabbed navigation: Overview, Modules, Dashboard, Terminal, Install
  - Animated terminal demo with live output simulation
  - Responsive design for mobile and desktop
  - Scroll animations and micro-interactions
- **Community & Repository Files**
  - `CODEOWNERS` — Code ownership and required reviewers
  - `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1
  - `CONTRIBUTING.md` — Comprehensive contribution guidelines
  - `SUPPORT.md` — Support channels and response times
  - `SECURITY.md` — Security policy and vulnerability reporting
  - `CHANGELOG.md` — Version history (this file)
  - `.github/CODEOWNERS` — Automated review assignments
  - `.github/dependabot.yml` — Automated dependency updates
  - `.github/workflows/security.yml` — Automated security scanning (ShellCheck, Trivy, CodeQL)
  - `.github/ISSUE_TEMPLATE/bug_report.md` — Bug report template
  - `.github/ISSUE_TEMPLATE/feature_request.md` — Feature request template
  - `.github/ISSUE_TEMPLATE/security_report.md` — Security issue template
  - `.github/PULL_REQUEST_TEMPLATE.md` — PR template with checklist
- **Documentation**
  - Screenshots of all GUI pages in `docs/screenshots/`
  - Updated README with screenshot gallery and v2.0 features

### Changed
- GUI completely redesigned from single-page to multi-tab dashboard
- Updated version badge from v1.0.0 to v2.0.0
- Improved `.gitignore` with comprehensive exclusion patterns

## [1.0.0] — 2026-03-07

### Added
- **30+ Security Modules** across 9 categories
  - Cloud Security: `cloud-audit`, `cloud-iam`, `cloud-network`
  - System Hardening: `harden-linux`, `harden-ssh`, `harden-kernel`, `harden-services`
  - Network Defense: `net-scan`, `net-firewall`, `net-dns`, `net-tls`
  - Vulnerability Assessment: `vuln-system`, `vuln-web`, `vuln-deps`
  - Compliance: `comply-cis`, `comply-iso27001`, `comply-pci`, `comply-password`
  - Log Analysis: `log-auth`, `log-syslog`
  - Incident Response: `ir-snapshot`, `ir-processes`, `ir-connections`, `ir-persistence`
  - Container Security: `container-docker`, `container-k8s`, `container-images`
  - Asset Inventory: `asset-inventory`, `asset-ports`
- `report_gen.sh` — HTML/TXT/JSON report generation
- Interactive menu + CLI mode
- Web GUI v1.0 (single-page showcase)
- MIT License

---

[2.0.0]: https://github.com/SiteQ8/KWT5h13ld/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/SiteQ8/KWT5h13ld/releases/tag/v1.0.0
