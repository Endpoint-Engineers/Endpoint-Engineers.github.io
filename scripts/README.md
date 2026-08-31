# Windows Update Remediation Toolkit

**Endpoint Engineers**

A PowerShell-based Windows Update detection and remediation solution designed for enterprise endpoint management and Microsoft Intune Remediations.

## What it does

The solution detects and remediates common Windows Update issues including:

* Windows Update service not running
* BITS service issues
* Cryptographic service issues
* Windows Update cache corruption
* Windows Update scan problems
* Common Windows Update service configuration issues

## Repository Structure

```text
windows-update-remediation/
│
├── Detection.ps1
├── Remediation.ps1
└── README.md
```

## Intune Deployment

The scripts can be deployed through:

**Microsoft Intune → Devices → Windows → Remediations**

Configure:

### Detection script

Upload:

`Detection.ps1`

### Remediation script

Upload:

`Remediation.ps1`

Recommended configuration:

* Run this script using the logged-on credentials: **No**
* Enforce script signature check: **No**, unless your organization signs scripts
* Run script in 64-bit PowerShell: **Yes**

## Remediation Workflow

```text
Endpoint
   │
   ▼
Detection Script
   │
   ├── Healthy
   │      └── Exit 0
   │
   └── Problem detected
          │
          ▼
      Remediation
          │
          ├── Check services
          ├── Restart services
          ├── Reset update cache
          ├── Reset Catroot2
          ├── Start services
          └── Trigger Windows Update scan
          │
          ▼
        Verify
```

## Logging

Remediation logs are stored locally at:

```text
C:\ProgramData\EndpointEngineers\WindowsUpdate\
```

Log file:

```text
WindowsUpdate-Remediation.log
```

## Disclaimer

Test the scripts in a controlled environment before deploying them broadly. Windows Update behavior can vary by Windows version, update configuration, management platform, security policy, and device state.

## Author

**Endpoint Engineers**

Automate. Secure. Monitor. Remediate.
