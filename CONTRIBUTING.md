# Contributing to KWT5H13LD

Thank you for your interest in contributing to **KWT5H13LD — Kuwait Shield Security Toolkit**! Every contribution makes the cybersecurity community stronger.

## Table of Contents

- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Module Development](#module-development)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)
- [Security](#security)
- [Community](#community)

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/KWT5h13ld.git
   cd KWT5h13ld
   ```
3. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes** and test thoroughly
5. **Push** and open a Pull Request

## How to Contribute

### 🐛 Reporting Bugs

- Use the [Bug Report](https://github.com/SiteQ8/KWT5h13ld/issues/new?template=bug_report.md) issue template
- Include your OS version, bash version, and steps to reproduce
- Attach relevant log output or screenshots

### 💡 Suggesting Features

- Use the [Feature Request](https://github.com/SiteQ8/KWT5h13ld/issues/new?template=feature_request.md) issue template
- Describe the use case and expected behavior
- If applicable, reference compliance frameworks or standards

### 🔧 Submitting Code

- Bug fixes, new modules, documentation improvements, and tests are all welcome
- Follow the coding standards below
- Ensure all existing tests still pass

### 📖 Improving Documentation

- Fix typos, improve clarity, add examples
- Update the GUI or README with new screenshots if UI changes are made

## Development Setup

```bash
# Clone and enter the project
git clone https://github.com/SiteQ8/KWT5h13ld.git
cd KWT5h13ld

# Make scripts executable
chmod +x kwt5h13ld.sh
chmod +x modules/*.sh

# Run the toolkit (requires root for some modules)
sudo ./kwt5h13ld.sh

# Run a specific module for testing
./kwt5h13ld.sh harden-ssh -v
```

### Prerequisites

- **Bash** 4.0+ (most Linux distributions)
- **Root access** for system-level security checks
- **Cloud CLI tools** (optional): `aws`, `az`, `gcloud` for cloud modules
- **Container tools** (optional): `docker`, `kubectl` for container modules

## Module Development

Each module lives in `modules/` and follows this structure:

```bash
#!/bin/bash
# Module: module_name.sh
# Category: [cloud|harden|net|vuln|comply|log|ir|container|asset]
# Description: Brief description of what this module does

module_name() {
    echo "[*] Running Module Name..."
    
    # Your security checks here
    # Use check_pass, check_fail, check_warn helpers
    
    echo "[*] Module complete."
}

# Execute if called directly
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && module_name "$@"
```

### Module Guidelines

- Each module should be **self-contained** and independently runnable
- Use the existing helper functions from `kwt5h13ld.sh`
- Map checks to compliance frameworks where applicable (CIS, ISO 27001, PCI DSS)
- Include pass/fail/warn status for each check
- Support both interactive and CLI modes

## Coding Standards

### Bash

- Use `#!/bin/bash` shebang
- Quote all variables: `"${variable}"`
- Use `[[ ]]` for conditionals (not `[ ]`)
- Functions use `snake_case` naming
- Add comments for non-obvious logic
- Use `local` for function-scoped variables
- Exit codes: `0` success, `1` general error, `2` missing dependency

### HTML/CSS/JS (GUI)

- Single-file architecture (HTML + CSS + JS in one file)
- Use CSS custom properties for theming
- Mobile-responsive design required
- No external JS frameworks (vanilla JS only)
- Semantic HTML5 elements

### General

- No trailing whitespace
- Use Unix line endings (LF, not CRLF)
- Keep lines under 120 characters where reasonable

## Pull Request Process

1. **Update documentation** if your change affects usage
2. **Test your changes** on at least one Linux distribution
3. **Fill out the PR template** completely
4. **Link related issues** using `Fixes #123` or `Closes #123`
5. **Request review** from `@SiteQ8`

### PR Checklist

- [ ] Code follows the project's coding standards
- [ ] Self-review of code performed
- [ ] Documentation updated (if applicable)
- [ ] No new warnings or errors introduced
- [ ] Tested on Linux environment
- [ ] Commit messages are clear and descriptive

## Security

**⚠️ IMPORTANT**: If you discover a security vulnerability, please **DO NOT** open a public issue. Instead, report it responsibly via our [Security Policy](SECURITY.md).

## Community

- **GitHub Issues**: Bug reports, feature requests, and discussions
- **GitHub Discussions**: General questions and community chat
- **Email**: Site@hotmail.com for direct communication

## Recognition

All contributors will be recognized in our changelog and release notes. Significant contributions may be highlighted in the README.

---

Thank you for helping make KWT5H13LD better! 🛡️🇰🇼
