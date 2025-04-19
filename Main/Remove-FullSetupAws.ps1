<#
.SYNOPSIS
    Removes the complete AWS infrastructure setup
.DESCRIPTION
    Orchestrates the removal of all AWS infrastructure components in the reverse order of deployment:
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
    Remove-FullSetupAws -labprofile "cflab-01"
    Removes the complete infrastructure from the cflab-01 profile
.EXAMPLE
    Remove-FullSetupAws -labprofile "all"
    Removes the complete infrastructure from all configured profiles
.NOTES
    - Requires valid AWS credentials and appropriate permissions
    - Must be run from the solution root folder
    - Will remove web applications for both AdminApp and StoreApp
.OUTPUTS
    None
#>
function Remove-FullSetupAws {
    [CmdletBinding()]
    param()

    Write-Host "Starting full removal setup..." -ForegroundColor Cyan

    # Get all lab profiles
    $labprofiles = Get-Accounts
    $accountsConfig = Get-Content -Path "accounts.yaml" -Raw | ConvertFrom-Yaml

    # Filter out excluded accounts
    $activeProfiles = $labprofiles | Where-Object { -not $accountsConfig.Accounts[$_].exclude }

    # 1. Remove Tenant Configurations across all accounts
    Write-Host "`nRemoving Tenant Configurations across all accounts..." -ForegroundColor Yellow
    $tenantRemovalSuccess = $true
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        $result = Remove-TenantsAws
        if (-not $result) {
            $tenantRemovalSuccess = $false
            Write-Host "Tenant removal failed for profile $profile" -ForegroundColor Red
        }
    }

    # 2. Remove Assets across all accounts
    Write-Host "`nRemoving System and Tenant Assets across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Remove-AssetsAws
    }

    # 3. Remove Web Applications across all accounts
    Write-Host "`nRemoving Web Applications across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        
        Write-Host "Removing MyApp..." -ForegroundColor Yellow
        Remove-WebappSimpleAws -ProjectFolder "MyApp"
        
        Write-Host "Removing StoreApp..." -ForegroundColor Yellow
        Remove-WebappSimpleAws -ProjectFolder "StoreApp"
        
        Write-Host "Removing AdminApp..." -ForegroundColor Yellow
        Remove-WebappSimpleAws -ProjectFolder "AdminApp"
    }

    # 4. Remove Service Infrastructure across all accounts
    Write-Host "`nRemoving Service Infrastructure across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Remove-ServiceNodeAws
    }

    # 5. Remove IAM Policies across all accounts
    Write-Host "`nRemoving IAM Policies across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Remove-PoliciesAws
    }

    # 6. Remove Authentication Configurations across all accounts
    Write-Host "`nRemoving Authentication Configurations across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Remove-AuthsAws
    }

    # 7. Remove System Infrastructure across all accounts
    Write-Host "`nRemoving System Infrastructure across all accounts..." -ForegroundColor Yellow
    foreach ($profile in $activeProfiles) {
        Write-Host "`nProcessing $profile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $profile
        Remove-SystemAws
    }

    if ($tenantRemovalSuccess) {
        Write-Host "`nFull removal setup completed!" -ForegroundColor Green
    } else {
        Write-Host "`nFull removal completed with tenant removal failures!" -ForegroundColor Yellow
    }
}
