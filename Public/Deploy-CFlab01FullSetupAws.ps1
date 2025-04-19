<#
.SYNOPSIS
    Deploys the complete AWS infrastructure setup
.DESCRIPTION
    Orchestrates the deployment of all AWS infrastructure components in the correct order:
    1. System infrastructure
    2. Authentication configurations
    3. IAM policies
    4. Service infrastructure
    5. Web applications (AdminApp and StoreApp)
    6. System and tenant assets
    7. Tenant configurations
.PARAMETER labprofile
    The AWS profile to use for deployment. Can be a specific profile (e.g., "cflab-01") or "all" to deploy to all profiles.
.EXAMPLE
    Deploy-CfLab01FullSetupAws -labprofile "cflab-01"
    Deploys the complete infrastructure to the cflab-01 profile
.EXAMPLE
    Deploy-CfLab01FullSetupAws -labprofile "all"
    Deploys the complete infrastructure to all configured profiles
.NOTES
    - Requires valid AWS credentials and appropriate permissions
    - Must be run from the solution root folder
    - Will deploy web applications for both AdminApp and StoreApp
    - Includes 30-second waits between deployments to allow resources to initialize
.OUTPUTS
    None
#>
function Deploy-CfLab01FullSetupAws {
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
        Deploy-FullSetupAws
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
        Deploy-FullSetupAws
    }
}