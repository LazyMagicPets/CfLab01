<#
.SYNOPSIS
    Deploys a tenant configuration to AWS
.DESCRIPTION
    Deploys or updates a tenant's configuration and resources in AWS environment,
    including necessary IAM roles, policies, and related resources.
.PARAMETER TenantKey
    The unique identifier for the tenant that matches a tenant defined in SystemConfig.yaml
.EXAMPLE
    Deploy-TenantAws -TenantKey "tenant123"
    Deploys the specified tenant configuration to AWS
.NOTES
    Requires valid AWS credentials and appropriate permissions
    The tenantKey must match a tenant defined in the SystemConfig.yaml file
.OUTPUTS
    None
#>
function Deploy-CfLab01TenantAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Deploy-TenantAws -Arguments @{ TenantKey = $TenantKey }
}

