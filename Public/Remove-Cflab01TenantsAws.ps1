<#
.SYNOPSIS
    Removes multiple tenant configurations from AWS
.DESCRIPTION
    Batch removes all tenant configurations defined in SystemConfig.yaml from AWS environment,
    handling all necessary resources and settings for each tenant.
.EXAMPLE
    Remove-Cflab01TenantsAws
    Removes all tenant configurations from SystemConfig.yaml
.NOTES
    Requires valid AWS credentials and appropriate permissions
.OUTPUTS
    None
#>
function Remove-Cflab01TenantsAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Remove-TenantsAws
}