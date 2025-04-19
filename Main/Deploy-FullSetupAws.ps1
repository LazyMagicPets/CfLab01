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
    Deploy-FullSetupAws -labprofile "cflab-01"
    Deploys the complete infrastructure to the cflab-01 profile
.EXAMPLE
    Deploy-FullSetupAws -labprofile "all"
    Deploys the complete infrastructure to all configured profiles
.NOTES
    - Requires valid AWS credentials and appropriate permissions
    - Must be run from the solution root folder
    - Will deploy web applications for both AdminApp and StoreApp
    - Includes 30-second waits between deployments to allow resources to initialize
.OUTPUTS
    None
#>
function Deploy-FullSetupAws {
    [CmdletBinding()]
    param()

    Write-Host "Starting full deployment setup..." -ForegroundColor Cyan

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

    # 1. Deploy System Infrastructure across all accounts
    Write-Host "`nDeploying System Infrastructure across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Deploy-SystemAws
    }

    # 2. Deploy Authentication Configurations across all accounts
    Write-Host "`nDeploying Authentication Configurations across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Deploy-AuthsAws
    }

    # 3. Deploy IAM Policies across all accounts
    Write-Host "`nDeploying IAM Policies across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Deploy-PoliciesAws
    }

    # 4. Deploy Service Infrastructure across all accounts
    Write-Host "`nDeploying Service Infrastructure across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Deploy-ServiceNodeAws
    }

    # 5. Deploy Web Applications across all accounts
    Write-Host "`nDeploying Web Applications across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        
        Write-Host "Deploying AdminApp..." -ForegroundColor Yellow
        Deploy-WebappSimpleAws -ProjectFolder "AdminApp"
        
        Write-Host "Deploying StoreApp..." -ForegroundColor Yellow
        Deploy-WebappSimpleAws -ProjectFolder "StoreApp"
        
        Write-Host "Deploying MyApp..." -ForegroundColor Yellow
        Deploy-WebappSimpleAws -ProjectFolder "MyApp"
    }

    # 6. Deploy Assets across all accounts
    Write-Host "`nDeploying System and Tenant Assets across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Deploy-AssetsAws
    }

    # 7. Deploy Tenant Configurations across all accounts
    Write-Host "`nDeploying Tenant Configurations across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Deploy-TenantsAws
    }

    Write-Host "`nFull deployment setup completed!" -ForegroundColor Green
}
