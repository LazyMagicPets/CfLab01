<#
.SYNOPSIS
    Removes the complete AWS infrastructure setup
.DESCRIPTION
    Orchestrates the removal of all AWS infrastructure components in the correct order:
    1. Tenant configurations
    2. System and tenant assets
    3. Web applications (AdminApp and StoreApp)
    4. Service infrastructure
    5. IAM policies
    6. Authentication configurations
    7. System infrastructure
.PARAMETER labprofile
    The AWS profile to use for removal. Can be a specific profile (e.g., "cflab-01") or "all" to remove from all profiles.
.EXAMPLE
    Remove-Cflab01FullSetupAws -labprofile "cflab-01"
    Removes the complete infrastructure from the cflab-01 profile
.EXAMPLE
    Remove-Cflab01FullSetupAws -labprofile "all"
    Removes the complete infrastructure from all configured profiles
.NOTES
    - Requires valid AWS credentials and appropriate permissions
    - Must be run from the solution root folder
    - Will remove web applications for both AdminApp and StoreApp
.OUTPUTS
    None
#>
function Remove-Cflab01FullSetupAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile
    )

    # Get all lab profiles in order from accounts.yaml
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    $accountsPath = Join-Path $moduleRoot "accounts.yaml"
    $accountsYaml = Get-Content -Path $accountsPath -Raw
    $accountsConfig = $accountsYaml | ConvertFrom-Yaml

    # Extract account names in order from the raw YAML
    $orderedAccounts = @()
    $accountsYaml -split "`n" | ForEach-Object {
        if ($_ -match '^\s*(\w+-\d+):') {
            $orderedAccounts += $Matches[1]
        }
    }

    # Filter out excluded accounts while maintaining order
    $activeProfiles = $orderedAccounts | Where-Object { -not $accountsConfig.Accounts[$_].exclude }

    if ($labprofile -eq "all") {
        # Call the full setup function directly - it will handle the looping
        Remove-FullSetupAws
    } else {
        # Validate the specified profile exists
        if ($orderedAccounts -notcontains $labprofile) {
            throw "Lab profile '$labprofile' not found in accounts.yaml"
        }

        # Skip if excluded
        if ($accountsConfig.Accounts[$labprofile].exclude) {
            Write-Host "Skipping $labprofile (excluded in accounts.yaml)" -ForegroundColor Yellow
            return
        }

        # Set the config for this profile and call the full setup
        Set-SystemConfig -labprofile $labprofile
        Remove-FullSetupAws
    }
}