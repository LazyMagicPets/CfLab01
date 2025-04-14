<#
.SYNOPSIS
    Removes service infrastructure and resources from AWS
.DESCRIPTION
    Removes service infrastructure from AWS including CloudFormation/SAM stacks,
    Lambda functions, and related AWS services.
.PARAMETER None
    This cmdlet does not accept any parameters. It uses system configuration files
    to determine what resources to remove.
.EXAMPLE
    Remove-Cflab01ServiceAws
    Removes the service infrastructure using settings from configuration files
.NOTES
    - Requires valid AWS credentials and appropriate permissions
    - Must be run from the AWSTemplates directory
    - Requires system configuration files
    - Will remove all service-related resources
.OUTPUTS
    None
#>
function Remove-Cflab01ServiceAws {
    [CmdletBinding()]
        param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Remove-ServiceNodeAws
}