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

    Deploy-Many -labprofile $labprofile -Function Deploy-FullSetupAws
}