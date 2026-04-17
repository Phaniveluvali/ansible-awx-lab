# WebSphere Application Server Deployment - Comprehensive Playbook Structure

## Project Overview
This project provides an enterprise-grade Ansible playbook for deploying IBM WebSphere Application Server (WAS) on Windows servers. It follows best practices for automation, includes proper error handling, validation, and supports multiple environments.

## Directory Structure

```
websphere/
├── deploy-was.yml              # Main playbook
├── ansible.cfg                 # Ansible configuration
├── inventory/                  # Inventory files
│   └── windows_was.ini        # Windows hosts inventory
├── group_vars/
│   └── windows_was.yml        # Group variables
├── profiles/                   # Environment profiles
│   ├── dev-profile.yml        # Development environment
│   ├── prod-profile.yml       # Production environment
│   └── test-profile.yml       # Test environment (optional)
├── roles/                      # Ansible roles
│   ├── prerequisites/          # Pre-deployment checks
│   ├── download/              # Download WAS installer
│   ├── install/               # Installation tasks
│   ├── configure/             # Configuration tasks
│   ├── start/                 # Start services
│   └── validate/              # Validation & testing
└── logs/                       # Deployment logs
```

## Features

✓ **Multi-environment support** (Dev, Prod, Test)
✓ **Administrator privilege validation**
✓ **Comprehensive pre-deployment checks**
✓ **Modular role-based architecture**
✓ **Tag-based execution control**
✓ **Detailed health checks and validation**
✓ **Error handling and rollback support**
✓ **Extensive logging and reporting**
✓ **Production-grade security settings**
✓ **Performance optimization configurations**

## Prerequisites

- Ansible 2.9+
- Python 3.6+
- Windows 10/Server 2016+ with WinRM enabled
- Administrator privileges on target Windows hosts
- Java 11 installed on target hosts
- Network access to WAS installer repository
- At least 10GB free disk space on installation drive

### Enable WinRM on Windows

```powershell
# Run as Administrator
winrm quickconfig
Enable-PSRemoting -Force
```

## Environment Profiles

### Development Environment (`dev-profile.yml`)
- WAS 9.0.5 (Express)
- 512MB-1GB JVM heap
- Debug logging enabled
- SSL disabled
- Connection pool: 20
- Single application server

### Production Environment (`prod-profile.yml`)
- WAS 9.0.5 (Full)
- 2GB-4GB JVM heap
- Info level logging
- SSL enabled
- Connection pool: 100
- IAM/Database integration
- High availability ready

## Usage

### 1. Update Inventory

Edit `inventory/windows_was.ini`:
```ini
[windows_was]
ws-app-server1 ansible_host=192.168.1.100 ansible_user=Administrator
ws-app-server2 ansible_host=192.168.1.101 ansible_user=Administrator
```

### 2. Set Environment and Password

```bash
# Source environment
source .env.dev  # or .env.prod

# Set Ansible password (interactive)
export ANSIBLE_PASSWORD=<windows_admin_password>

# Or use vault (recommended for production)
# ansible-vault create .vault_password
# export ANSIBLE_VAULT_PASSWORD_FILE=.vault_password
```

### 3. Run Deployment

#### Full Deployment (All stages)
```bash
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "environment=dev"
```

#### Run Specific Stages (Using Tags)

**Prerequisites only:**
```bash
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "environment=dev" \
  --tags prerequisites
```

**Download installer:**
```bash
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "environment=dev" \
  --tags download
```

**Install and configure:**
```bash
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "environment=dev" \
  --tags deploy
```

**Start services:**
```bash
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "environment=dev" \
  --tags start
```

**Validation and testing:**
```bash
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "environment=dev" \
  --tags test
```

#### Skip Stages

```bash
# Skip download stage (installer already present)
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "environment=prod" \
  --skip-tags download
```

## Available Tags

| Tag | Purpose | When to Use |
|-----|---------|------------|
| `prerequisites` | Pre-deployment validation | Initial setup, verify requirements |
| `download` | Download WAS installer | Fresh installations |
| `install` | Installation and profile creation | New deployments |
| `configure` | Apply configurations | After installation |
| `deploy` | Install + Configure | Full install cycle |
| `start` | Start application servers | Service startup |
| `test` | Validate deployment | Health checks |
| `always` | Runs regardless of tags | Essential tasks |

## Ansible Tower/AWX Integration

### Job Template Setup

1. **Create Job Template:**
   - Name: `Deploy WebSphere Application Server`
   - Playbook: `deploy-was.yml`
   - Inventory: Select Windows inventory
   - Vault: Add vault credential if using encrypted variables

2. **Configure Variables:**
   - In "Extra Variables" section:
   ```yaml
   environment: dev
   ```

3. **Set Verbosity:**
   - For debug output: Select `-v` (Verbose)
   - For production: Default or `-q` (Quiet)

4. **Create Survey/Prompt:**
   - Ask which tags to run
   - Ask which environment (dev/prod)
   - Ask for confirmation before deployment

### Execute from Tower

```bash
# Via CLI - trigger Tower job
tower-cli job launch \
  --job-template="Deploy WebSphere Application Server" \
  --inventory="Windows Hosts" \
  --extra-vars='{"environment": "dev"}' \
  --tags="prerequisites,install,configure" \
  -v

# Or use the Web UI:
# Jobs > Launch > Select Job Template > Configure > Launch
```

## Configuration Customization

### Custom JVM Arguments
Edit the appropriate profile file:

```yaml
# In profiles/dev-profile.yml
jvm_generic_jvm_args: "-Xgcpolicy:gencon -Djava.awt.headless=true -Duser.timezone=UTC"
```

### Add Database Connection
```yaml
# In profiles/prod-profile.yml
database_enabled: true
database_host: "db-prod.internal"
database_port: "5432"
database_name: "wasdb"
database_user: "wasdbuser"
# password in vault: ansible-vault edit group_vars/windows_was.yml
```

### Customize Ports
```yaml
was_http_port: 8080       # Default
was_https_port: 8443      # Default
was_admin_port: 9060      # Admin console
was_admin_secure_port: 9043  # Secure admin
```

## Validation and Testing

The playbook includes comprehensive validation:

- ✓ Administrator privilege verification
- ✓ Java installation check
- ✓ Disk space validation
- ✓ Windows version compatibility
- ✓ Network connectivity
- ✓ Port availability
- ✓ Service startup verification
- ✓ Admin console accessibility
- ✓ Event log monitoring

View validation reports in the playbook output or in logs:
```bash
tail -f logs/ansible.log
```

## Troubleshooting

### WinRM Connection Issues
```bash
# Test WinRM connectivity
ansible all -i inventory/windows_was.ini -m win_ping

# Increase verbosity for debugging
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  -vvvv
```

### Installer Download Fails
- Verify network access to repository
- Check URL in profile file
- Verify checksum matches downloaded file

### Java Not Found
```powershell
# On Windows target, verify Java installation
java -version

# Check JAVA_HOME
echo $env:JAVA_HOME
```

### Low Disk Space
- Ensure at least 10GB free on C: drive
- Clean temp directory: `C:\temp\was_install`
- Check log files in WAS installation directory

### Service Fails to Start
```bash
# Enable debug logging
ansible-playbook deploy-was.yml \
  --extra-vars "enable_debug=true" \
  --tags start

# Check event logs for errors
```

## Security Best Practices

1. **Credential Management:**
   - Use Ansible Vault for sensitive data
   - Never commit passwords to version control
   - Use Tower credential store in production

2. **SSL/TLS:**
   - Enable SSL in production environment
   - Use proper certificates, not self-signed
   - Enforce HTTPS for admin console

3. **Access Control:**
   - Limit who can run deployments (RBAC in Tower)
   - Use dedicated service accounts
   - Audit all deployment activities

4. **Network Security:**
   - Restrict WinRM to specific subnets
   - Use SSH tunneling for remote execution
   - Implement network segmentation

## Rollback Procedure

To rollback to a previous state:

```bash
# If deployment fails mid-way, clean up:
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "environment=dev" \
  --tags rollback  # (not yet implemented - add to deploy-was.yml as needed)
```

## Performance Optimization

For large-scale deployments:

```bash
# Increase parallelization
ansible-playbook deploy-was.yml \
  --forks 20 \
  --inventory inventory/windows_was.ini

# Use async execution
ansible-playbook deploy-was.yml \
  --inventory inventory/windows_was.ini \
  --extra-vars "installation_timeout=7200"
```

## Support and Contribution

For issues, feature requests, or contributions:
1. Check existing logs in `logs/` directory
2. Enable verbose output for debugging
3. Document any modifications to profiles
4. Test in dev environment before using in production

## References

- [Ansible Windows Documentation](https://docs.ansible.com/ansible/latest/user_guide/windows.html)
- [IBM WebSphere Application Server Documentation](https://ibmdocs.github.io/was/)
- [Windows Remote Management (WinRM)](https://docs.microsoft.com/en-us/windows/win32/winrm/portal)

## License and Disclaimer

Use at your own risk. Test thoroughly in non-production environments before deploying to production. Ensure compliance with your organization's change management policies.

---

**Last Updated:** April 2026
**Maintained By:** DevOps Team
**Version:** 1.0
