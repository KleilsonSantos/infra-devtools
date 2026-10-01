# 🛡️ Security Policy

## 🎯 Supported Versions

Versões do projeto que recebem atualizações de segurança:

| Version | Supported          | Security Status |
| ------- | ------------------ | --------------- |
| 1.3.x   | Yes                | Active          |
| 1.2.x   | Limited            | Maintenance     |
| < 1.2   | No                 | End of Life     |

## 🚨 Reporting a Vulnerability

### 📧 Contact Information

Para relatar vulnerabilidades de segurança:

**Email**: kleilsonsantos0907@gmail.com
**Subject**: `[SECURITY] Infra DevTools - Vulnerability Report`

**⚠️ IMPORTANTE**: **NÃO** crie issues públicas no GitHub para vulnerabilidades de segurança.

### 📋 Report Template

```
## Vulnerability Details
- **Component**: [Affected service/script/configuration]
- **Severity**: [Critical/High/Medium/Low]
- **Type**: [Authentication/Authorization/Injection/Data Exposure/etc]
- **CVSS Score**: [If applicable]

## Description
[Detailed description of the vulnerability]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Proof of Concept
[Code, commands, or screenshots demonstrating the issue]

## Impact
[Potential impact on confidentiality, integrity, availability]
- Confidentiality: [Low/Medium/High]
- Integrity: [Low/Medium/High]
- Availability: [Low/Medium/High]

## Affected Versions
[Versions affected by this vulnerability]

## Suggested Fix
[If you have suggestions for remediation]
```

### ⏱️ Response Timeline

- **Acknowledgment**: Within 24 hours
- **Initial Assessment**: Within 72 hours
- **Fix Development**: Within 7-14 days (depending on severity)
- **Critical Hotfix**: Within 48-72 hours for CVSS >= 8.0
- **Public Disclosure**: After fix is released and users have time to update

## 🛡️ Security Measures Implemented

### Trust boundary (read this first)

This repository is a **local Docker Compose DevOps kit**. Default posture assumes a single-developer laptop. It is **not** production-hardened. Published Compose ports bind on all interfaces unless you override them; Vault local config disables TLS on purpose (`vault/config/vault-config.hcl`).

### 🔐 Credential Management
- `.env` gitignored; `.env.development` is an empty tracked template
- Local Vault (file backend) with init/seed scripts; root/unseal files under `target/vault-dev-*.txt` (gitignored)
- PR CI validates `.env.development` **template presence** only (does not inject live secrets)
- Optional Base64 encode helper for GitHub secrets (`scripts/encode-env.sh`) — operator-managed

### 🗂️ File System Security
- Logs / caches ignored (`logs/`, `__pycache__/`, etc.)
- Backup artifacts ignored (`backups/`, `*.backup`, `*.bak`)
- Key material patterns ignored (`*.key`, `*.pem`, `*.crt`, `*.p12`, `*.pfx`)
- Vault data dir ignored (`vault/data/*`)

### 🐳 Container Security
- Shared bridge network for the kit stack
- Named volumes for persistence
- **Portainer is opt-in** (`--profile tools`) because it mounts the Docker socket (host-root equivalent) — see #71
- cAdvisor mounts host paths read-only when enabled — treat as sensitive
- Non-root users recommended for any production fork of this stack
- Image pins are partial (Vault pinned; many services still float — tracked in #73)

### 📊 Monitoring & Observability
- Prometheus / Grafana / Alertmanager present in Compose
- Some alert expressions are still stubs (`expr: 1 == bool 1`) — tracked in #74; do not treat them as real detection yet
- SonarQube available as a local service (manual scanner)

### 🔄 CI/CD Security
- **Fail-closed** PR Validation on `sandbox` / `main` (formats, unit tests, Bandit, VERSION SSOT, issue-link)
- Local hooks: `.githooks` + `scripts/preflight.sh` (`npm run prepare`) — bypassable with `--no-verify`; CI remains authoritative
- Scheduled workflow runs **Bandit fail-closed**; deep Trivy/host audits are **local** via `scripts/security-audit.sh` (not claimed as merge gates) — #70
- GitHub secret scanning + push protection enabled at repo settings
- Branch protection enabled on `main` and `sandbox` (required status checks) — #69
- Dependabot config file and CodeQL workflow are not in-tree yet (#73/#09 follow-ups)

### 🔍 Code Quality & Security Tools

**Python Stack:**
- ✅ **Bandit**: Security linting (skips B101, B110)
- ✅ **Flake8**: Code style + security checks
- ✅ **Pylint**: Deep code analysis (complexity < 12)
- ✅ **MyPy**: Type checking
- ✅ **Black**: Auto-formatting (prevents code injection via formatting)

**JavaScript/TypeScript:**
- ✅ **ESLint**: Linting with security plugins
- ✅ **Prettier**: Consistent formatting
- ⚠️ **npm audit**: Manual execution recommended

**Dependencies:**
- ✅ **OWASP Dependency-Check**: Automated via `make check-deps`
- ✅ **Snyk**: Available in package.json

## ⚠️ Known Security Considerations

### 🏠 Local Development Focus
This project is designed for **local development environments** and includes:

- Operator-supplied credentials via `.env` (template is empty)
- Service ports published on the Docker host (default bind is all interfaces — restrict with firewall or `127.0.0.1:` binds)
- HTTP (not HTTPS) between kit services; Vault TLS disabled locally on purpose
- Portainer only when explicitly started with Compose profile `tools`

### 🚀 Production Hardening Required
Before production deployment:

1. **🔑 Change ALL Default Credentials**
   ```bash
   # Generate secure passwords
   openssl rand -base64 32

   # Update in .env:
   POSTGRES_PASSWORD=<generated>
   MONGO_INITDB_ROOT_PASSWORD=<generated>
   MYSQL_ROOT_PASSWORD=<generated>
   REDIS_PASSWORD=<generated>
   RABBITMQ_DEFAULT_PASS=<generated>
   KEYCLOAK_ADMIN_PASSWORD=<generated>
   ```

2. **🔒 Enable HTTPS/TLS**
   ```bash
   # Use reverse proxy (Nginx/Traefik) with valid certificates
   # Let's Encrypt for automated SSL
   # Configure all services to use HTTPS
   ```

3. **🌐 Configure Proper Networking**
   ```bash
   # Use internal networks only
   # Implement proper firewall rules (UFW, iptables)
   # Expose only necessary ports
   # Consider VPN access (WireGuard, OpenVPN)
   ```

4. **📋 Review Permissions**
   ```bash
   # Apply principle of least privilege
   # Audit all service accounts
   # Disable unnecessary services
   # Configure SELinux/AppArmor
   ```

5. **🔐 Vault Configuration**
   ```bash
   # Initialize Vault with production settings
   # Enable encryption at rest
   # Configure auto-unseal
   # Implement proper access policies
   ```

6. **📊 Enable Audit Logging**
   ```bash
   # Configure centralized logging (ELK, Loki)
   # Enable audit logs for all databases
   # Set up log retention policies
   # Monitor for suspicious activity
   ```

## 🔍 Security Audit History

### 2025-11-06 - Initial Security Assessment
- **Scope**: Project structure and configuration review
- **Status**: Baseline security posture established
- **Actions Taken**:
  - Enhanced .gitignore with security-focused exclusions
  - Created SECURITY.md policy
  - Documented supported versions
  - Established vulnerability reporting process

**Security Posture**:
- ✅ Strong code quality tooling (8+ tools)
- ✅ Comprehensive monitoring stack
- ✅ Environment variable management
- ⚠️ No automated security audits in CI
- ⚠️ Default credentials in development
- ⚠️ Missing container image scanning

### Future Audits
- **Quarterly Reviews**: Every 3 months (next: 2026-02-06)
- **Dependency Scanning**: Weekly automated scans (to be implemented)
- **Container Scanning**: Trivy/Grype integration (planned)
- **Penetration Testing**: Annual third-party assessment

## 📚 Security Best Practices

### For Contributors
1. **Never commit secrets** - Use `.env.development` for templates
2. **Follow conventional commits** - Maintain clear audit trail
3. **Run security tests** - Execute `make lint-bandit` before committing
4. **Use provided tools** - Leverage pre-commit hooks and linters
5. **Review dependencies** - Run `make check-deps` regularly
6. **Test changes** - Ensure all tests pass with `make test-all`

### For Users
1. **Change default passwords** - **First step** after deployment
2. **Keep services updated** - Regular Docker image updates
3. **Monitor logs** - Check Grafana dashboards regularly
4. **Backup regularly** - Use automated backup system (to be implemented)
5. **Review access logs** - Check for unauthorized access attempts
6. **Update dependencies** - Run `npm audit fix` and update Python packages

### For Administrators
1. **Network isolation** - Deploy behind firewalls/VPN
2. **Access control** - Implement proper authentication (Keycloak integration)
3. **Audit trails** - Enable comprehensive logging in all services
4. **Incident response** - Have a security incident response plan
5. **Backup & Recovery** - Test restore procedures quarterly
6. **Resource limits** - Configure Docker resource constraints

## 🚨 Security Incidents

### Incident Response Process

1. **Detection**: Alert via monitoring or user report
2. **Assessment**: Severity classification (Critical/High/Medium/Low)
3. **Containment**: Isolate affected services
4. **Eradication**: Remove vulnerability/threat
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Document and improve

### Incident Contacts
- **Primary**: kleilsonsantos0907@gmail.com
- **GitHub Issues**: https://github.com/KleilsonSantos/infra-devtools/issues (non-security only)

## 📦 Dependency Security

### Automated Scanning
```bash
# OWASP Dependency-Check
make check-deps

# npm audit
npm audit

# Python dependencies (pip-audit - to be added)
pip-audit
```

### Update Policy
- **Critical vulnerabilities**: Immediate update within 24-48 hours
- **High severity**: Update within 7 days
- **Medium/Low**: Update in next scheduled release

## 📞 Additional Resources

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **Docker Security**: https://docs.docker.com/engine/security/
- **Kubernetes Security**: https://kubernetes.io/docs/concepts/security/ (future)
- **CI/CD Security**: https://owasp.org/www-project-devsecops-guideline/
- **Python Security**: https://bandit.readthedocs.io/
- **Node.js Security**: https://nodejs.org/en/docs/guides/security/

## 🏆 Security Certifications & Standards

### Compliance Goals
- **CIS Docker Benchmark**: Targeted compliance (future)
- **OWASP ASVS**: Application Security Verification Standard
- **NIST Cybersecurity Framework**: Best practices alignment

---

**Last Updated**: 2026-10-01
**Version**: 1.3.1
**Next Review**: 2026-12-01
**Security Contact**: kleilsonsantos0907@gmail.com
