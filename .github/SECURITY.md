# Security Policy

## Supported Versions

Currently, security updates are provided for the following versions:

| Version | Support Status |
| ------- | -------------- |
| 1.x     | :white_check_mark: Supported |

## Reporting a Vulnerability

If you discover a security vulnerability, please **do not** submit a public issue.

### Reporting Process

1. **Send an email** to [security@yflow.io](mailto:security@yflow.io)
2. **Include the following information**:
   - Description of the vulnerability
   - Affected versions
   - Steps to reproduce (if applicable)
   - Potential impact
   - Suggested fix (if available)

### Response Commitment

* We will acknowledge receipt within **48 hours**
* We will assess the vulnerability and determine a response plan within **7 days**
* We will notify you when a fix is available
* We will credit your contribution in the security advisory (unless you request anonymity)

### Security Updates

When releasing security updates, we will:

1. Publish a new release on GitHub
2. Mark security fixes in the release notes
3. Advise users to upgrade to the secure version promptly

## Best Practices

### For Users

* Keep your YFlow instance updated to the latest version
* Never commit configuration files with sensitive information to public repositories
* Use strong passwords and enable two-factor authentication (if supported)
* Regularly review access logs and user activity

### For Developers

* Follow [secure coding practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
* Validate and sanitize all user input
* Use parameterized queries to prevent SQL injection
* Keep dependencies up to date
* Review code for security issues during pull requests

## Security Configuration

### Production Deployment Checklist

Before deploying to production, ensure:

- [ ] Change the default admin password
- [ ] Set strong password policies
- [ ] Enable HTTPS
- [ ] Configure firewall rules
- [ ] Rate-limit API access
- [ ] Regularly back up the database
- [ ] Configure log monitoring
- [ ] Set environment variables instead of hardcoding sensitive information

### Environment Variables

Make sure the following sensitive information is configured via environment variables:

```bash
# Database
DB_ROOT_PASSWORD
DB_PASSWORD

# JWT
JWT_SECRET
JWT_REFRESH_SECRET

# CLI
CLI_API_KEY
```

## Contact

* **Security issues**: [security@yflow.io](mailto:security@yflow.io)
* **General questions**: [GitHub Issues](https://github.com/ishechuan/yflow/issues)

---

*Thank you for helping keep YFlow secure!*
