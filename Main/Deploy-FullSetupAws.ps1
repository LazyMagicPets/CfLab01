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

    # 1. Deploy System Infrastructure
    Write-Host "`nDeploying System Infrastructure..." -ForegroundColor Yellow
    Deploy-SystemAws
    Write-Host "Waiting 30 seconds for resources to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # 2. Deploy Authentication Configurations
    Write-Host "`nDeploying Authentication Configurations..." -ForegroundColor Yellow
    Deploy-AuthsAws
    Write-Host "Waiting 30 seconds for resources to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # 3. Deploy IAM Policies
    Write-Host "`nDeploying IAM Policies..." -ForegroundColor Yellow
    Deploy-PoliciesAws
    Write-Host "Waiting 30 seconds for resources to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # 4. Deploy Service Infrastructure
    Write-Host "`nDeploying Service Infrastructure..." -ForegroundColor Yellow
    Deploy-ServiceNodeAws
    Write-Host "Waiting 30 seconds for resources to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # 5. Deploy Web Applications
    Write-Host "`nDeploying Web Applications..." -ForegroundColor Yellow
    Write-Host "Deploying AdminApp..." -ForegroundColor Yellow
    Deploy-WebappSimpleAws -ProjectFolder "AdminApp"
    Write-Host "Waiting 30 seconds for resources to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    Write-Host "Deploying StoreApp..." -ForegroundColor Yellow
    Deploy-WebappSimpleAws -ProjectFolder "StoreApp"
    Write-Host "Waiting 30 seconds for resources to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # 6. Deploy Assets
    Write-Host "`nDeploying System and Tenant Assets..." -ForegroundColor Yellow
    Deploy-AssetsAws
    Write-Host "Waiting 30 seconds for resources to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # 7. Deploy Tenant Configurations
    Write-Host "`nDeploying Tenant Configurations..." -ForegroundColor Yellow
    Deploy-TenantsAws

    Write-Host "`nFull deployment setup completed!" -ForegroundColor Green
}
