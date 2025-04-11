<#
.SYNOPSIS
    Deploys multiple tenant configurations to AWS
.DESCRIPTION
    Batch deploys all tenant configurations defined in SystemConfig.yaml to AWS environment,
    handling all necessary resources and settings for each tenant.
.EXAMPLE
    Deploy-TenantsAws
    Deploys all tenant configurations from SystemConfig.yaml
.NOTES
    Requires valid AWS credentials and appropriate permissions
.OUTPUTS
    None
#>
function Deploy-CfLab01TenantsAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Deploy-TenantsAws 
}

