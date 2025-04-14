<#
.SYNOPSIS
    Removes system-wide AWS infrastructure
.DESCRIPTION
    Removes core system infrastructure components from AWS, including
    the main system stack and system resources.
.PARAMETER None
    This cmdlet does not accept parameters directly, but reads from system configuration
.EXAMPLE
    Remove-Cflab01SystemAws
    Removes the system infrastructure based on configuration in systemconfig.yaml
.NOTES
    - Must be run from the Tenancy Solution root folder
    - Requires valid AWS credentials and appropriate permissions
    - Uses AWS SAM CLI for deployments
.OUTPUTS
    None
#>
function Remove-Cflab01SystemAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Remove-SystemAws
}
