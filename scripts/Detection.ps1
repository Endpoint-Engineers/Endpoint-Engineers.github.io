#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Detects common Windows Update service issues.

.DESCRIPTION
    Designed for Microsoft Intune Remediations.
    Returns exit code 1 when remediation is required.
    Returns exit code 0 when no remediation is required.

.AUTHOR
    Endpoint Engineers

.VERSION
    1.0.0
#>

$ErrorActionPreference = "SilentlyContinue"

$RequiredServices = @(
    "wuauserv",
    "BITS",
    "cryptsvc"
)

$RemediationRequired = $false
$Issues = @()

foreach ($ServiceName in $RequiredServices) {

    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if (-not $Service) {
        $Issues += "Service not found: $ServiceName"
        $RemediationRequired = $true
        continue
    }

    if ($Service.Status -ne "Running") {
        $Issues += "$ServiceName is $($Service.Status)"
        $RemediationRequired = $true
    }
}

# Check Windows Update service startup configuration
$WUService = Get-CimInstance Win32_Service `
    -Filter "Name='wuauserv'" `
    -ErrorAction SilentlyContinue

if ($WUService -and $WUService.StartMode -eq "Disabled") {
    $Issues += "Windows Update service is disabled"
    $RemediationRequired = $true
}

if ($RemediationRequired) {

    Write-Output "Remediation required."
    $Issues | ForEach-Object {
        Write-Output " - $_"
    }

    exit 1
}

Write-Output "Windows Update services are healthy."
exit 0