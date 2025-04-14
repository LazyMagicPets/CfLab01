<#
.SYNOPSIS
    Removes a tenant configuration from AWS
.DESCRIPTION
    Removes a tenant's configuration and resources from AWS environment,
    including necessary IAM roles, policies, and related resources.
.PARAMETER TenantKey
    The unique identifier for the tenant that matches a tenant defined in SystemConfig.yaml
.EXAMPLE
    Remove-Cflab01TenantAws -TenantKey "tenant123"
    Removes the specified tenant configuration from AWS
.NOTES
    Requires valid AWS credentials and appropriate permissions
    The tenantKey must match a tenant defined in the SystemConfig.yaml file
.OUTPUTS
    None
#>
function Remove-CfLab01TenantAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile
    )

    Deploy-Many -labprofile $labprofile -Function Remove-TenantAws -Arguments @{ TenantKey = $TenantKey }
}
