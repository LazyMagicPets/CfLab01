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

    Deploy-Many -labprofile $labprofile -Function Remove-FullSetupAws
}