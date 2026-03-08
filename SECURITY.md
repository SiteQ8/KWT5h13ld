# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | ✅ Active support  |
| 1.0.x   | ⚠️ Security fixes only |
| < 1.0   | ❌ End of life     |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in KWT5H13LD, please report it responsibly.

### How to Report

**⚠️ DO NOT open a public GitHub issue for security vulnerabilities.**

Instead, please report vulnerabilities via:

1. **Email**: Send details to [Site@hotmail.com](mailto:Site@hotmail.com)
2. **Subject line**: `[SECURITY] KWT5H13LD — Brief Description`
3. **GitHub Security Advisories**: [Report a vulnerability](https://github.com/SiteQ8/KWT5h13ld/security/advisories/new)

### What to Include

- Type of vulnerability (e.g., command injection, path traversal, privilege escalation)
- Affected component(s) and version(s)
- Step-by-step instructions to reproduce
- Proof of concept (if available)
- Impact assessment
- Suggested fix (if any)

### Response Timeline

| Stage | Timeline |
| --- | --- |
| Acknowledgment | Within 48 hours |
| Initial assessment | Within 1 week |
| Patch development | Within 2 weeks |
| Public disclosure | After patch release |

### Responsible Disclosure

We follow a coordinated disclosure process:

1. Reporter submits vulnerability details privately
2. We acknowledge receipt and begin assessment
3. We develop and test a fix
4. We release the patch and publish a security advisory
5. Reporter is credited (unless they prefer anonymity)

### Scope

The following are **in scope** for security reports:

- The `kwt5h13ld.sh` main script
- All modules in the `modules/` directory
- The web GUI in `gui/`
- CI/CD workflows in `.github/`
- Documentation that could lead to insecure configurations

The following are **out of scope**:

- Issues in third-party tools that KWT5H13LD calls (e.g., nmap, docker, aws-cli)
- Social engineering attacks
- Denial of service attacks against the GitHub repository
- Issues that require physical access to the system

## Security Best Practices

When using KWT5H13LD:

- **Always** obtain authorization before scanning systems
- **Never** run the toolkit against systems you don't own or have permission to test
- **Review** module output before sharing — it may contain sensitive system information
- **Protect** generated reports — they contain security posture details
- **Update** to the latest version for security fixes

## Hall of Fame

We gratefully acknowledge security researchers who have responsibly disclosed vulnerabilities:

*Be the first to contribute a security report!*

---

🛡️ **KWT5H13LD** — Guarding Kuwait's Cyber Gates
