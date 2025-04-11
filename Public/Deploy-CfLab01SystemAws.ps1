<#
.SYNOPSIS
    Deploys system-wide AWS infrastructure
.DESCRIPTION
    Deploys or updates core system infrastructure components in AWS using SAM templates.
    First deploys system resources, then deploys the main system stack which includes
    key-value store and other foundational services.
.PARAMETER None
    This cmdlet does not accept parameters directly, but reads from system configuration
.EXAMPLE
    Deploy-SystemAws
    Deploys the system infrastructure based on configuration in systemconfig.yaml
.NOTES
    - Must be run from the Tenancy Solution root folder
    - Requires valid AWS credentials and appropriate permissions
    - Uses AWS SAM CLI for deployments
.OUTPUTS
    None
#>
function Deploy-CfLab01SystemAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Deploy-SystemAws
}
