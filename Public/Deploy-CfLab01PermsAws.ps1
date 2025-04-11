<#
.SYNOPSIS
    Deploys the sam.perms.yaml stack
.DESCRIPTION
    The perms stack allows the creation of service permissions, like 
    giving a lambda execution role access to a cognito user pool.
.PARAMETER None
    This cmdlet does not accept parameters directly, but reads from system configuration
.EXAMPLE
    Deploy-PermsAws
    Deploys the system infrastructure based on the sam.perms.yaml template
.NOTES
    - Must be run from the Tenancy Solution root folder
    - Requires valid AWS credentials and appropriate permissions
    - Uses AWS SAM CLI for deployments
.OUTPUTS
    None
#>
function Deploy-CfLab01PermsAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Deploy-PermsAws
}
