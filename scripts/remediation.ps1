#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Remediates common Windows Update service and cache issues.

.DESCRIPTION
    Designed for Microsoft Intune Remediations.

    Actions:
    1. Ensures required services are running.
    2. Corrects Windows Update service startup configuration.
    3. Stops Windows Update-related services.
    4. Resets SoftwareDistribution cache.
    5. Resets Catroot2 cache.
    6. Starts services again.
    7. Triggers a Windows Update scan.
    8. Writes a remediation log.

.AUTHOR
    Endpoint Engineers

.VERSION
    1.0.0
#>

$ErrorActionPreference = "Continue"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$LogDirectory = "$env:ProgramData\EndpointEngineers\WindowsUpdate"
$LogFile = Join-Path $LogDirectory "WindowsUpdate-Remediation.log"

$Services = @(
    "wuauserv",
    "BITS",
    "cryptsvc"
)

# ------------------------------------------------------------
# Create log directory
# ------------------------------------------------------------

if (-not (Test-Path $LogDirectory)) {
    New-Item -Path $LogDirectory `
             -ItemType Directory `
             -Force | Out-Null
}

function Write-Log {
    param (
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$Timestamp`t$Message" |
        Out-File -FilePath $LogFile `
                 -Append `
                 -Encoding UTF8

    Write-Output $Message
}

Write-Log "=========================================="
Write-Log "Windows Update remediation started"
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "=========================================="

# ------------------------------------------------------------
# Step 1 - Check Windows Update service
# ------------------------------------------------------------

Write-Log "Checking Windows Update service configuration."

$WUService = Get-Service `
    -Name "wuauserv" `
    -ErrorAction SilentlyContinue

if ($WUService) {

    try {

        Set-Service `
            -Name "wuauserv" `
            -StartupType Manual `
            -ErrorAction Stop

        Write-Log "Windows Update startup configuration verified."

    }
    catch {

        Write-Log "Unable to modify Windows Update startup configuration: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Step 2 - Stop Windows Update services
# ------------------------------------------------------------

Write-Log "Stopping Windows Update services."

foreach ($ServiceName in $Services) {

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if ($Service) {

        try {

            if ($Service.Status -eq "Running") {

                Stop-Service `
                    -Name $ServiceName `
                    -Force `
                    -ErrorAction Stop

                Write-Log "Stopped service: $ServiceName"
            }
            else {

                Write-Log "$ServiceName is already stopped."
            }
        }
        catch {

            Write-Log "Failed to stop $ServiceName : $($_.Exception.Message)"
        }
    }
}

Start-Sleep -Seconds 5

# ------------------------------------------------------------
# Step 3 - Reset SoftwareDistribution
# ------------------------------------------------------------

$SoftwareDistribution = "$env:SystemRoot\SoftwareDistribution"

if (Test-Path $SoftwareDistribution) {

    $BackupPath = "$SoftwareDistribution.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"

    try {

        Rename-Item `
            -Path $SoftwareDistribution `
            -NewName (Split-Path $BackupPath -Leaf) `
            -ErrorAction Stop

        Write-Log "SoftwareDistribution cache renamed."

    }
    catch {

        Write-Log "Unable to rename SoftwareDistribution: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Step 4 - Reset Catroot2
# ------------------------------------------------------------

$Catroot2 = "$env:SystemRoot\System32\catroot2"

if (Test-Path $Catroot2) {

    $CatrootBackup = "$Catroot2.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"

    try {

        Rename-Item `
            -Path $Catroot2 `
            -NewName (Split-Path $CatrootBackup -Leaf) `
            -ErrorAction Stop

        Write-Log "Catroot2 cache renamed."

    }
    catch {

        Write-Log "Unable to rename Catroot2: $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Step 5 - Start services
# ------------------------------------------------------------

Write-Log "Starting Windows Update services."

foreach ($ServiceName in $Services) {

    try {

        Start-Service `
            -Name $ServiceName `
            -ErrorAction Stop

        Write-Log "Started service: $ServiceName"

    }
    catch {

        Write-Log "Failed to start $ServiceName : $($_.Exception.Message)"
    }
}

Start-Sleep -Seconds 10

# ------------------------------------------------------------
# Step 6 - Verify services
# ------------------------------------------------------------

Write-Log "Verifying Windows Update services."

$Healthy = $true

foreach ($ServiceName in $Services) {

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if ($Service -and $Service.Status -eq "Running") {

        Write-Log "$ServiceName = Running"

    }
    else {

        Write-Log "$ServiceName = NOT RUNNING"
        $Healthy = $false
    }
}

# ------------------------------------------------------------
# Step 7 - Trigger Windows Update scan
# ------------------------------------------------------------

$UsoClient = "$env:SystemRoot\System32\UsoClient.exe"

if (Test-Path $UsoClient) {

    try {

        Start-Process `
            -FilePath $UsoClient `
            -ArgumentList "StartScan" `
            -WindowStyle Hidden `
            -ErrorAction Stop

        Write-Log "Windows Update scan triggered."

    }
    catch {

        Write-Log "Unable to trigger Windows Update scan: $($_.Exception.Message)"
    }
}
else {

    Write-Log "UsoClient.exe not found."
}

# ------------------------------------------------------------
# Step 8 - Final result
# ------------------------------------------------------------

if ($Healthy) {

    Write-Log "Windows Update remediation completed successfully."
    Write-Log "Log file: $LogFile"

    Write-Output "Windows Update remediation completed."
    exit 0
}
else {

    Write-Log "Windows Update remediation completed with service errors."

    Write-Output "Windows Update remediation completed with errors."
    exit 1
}