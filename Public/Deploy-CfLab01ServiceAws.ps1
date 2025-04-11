<#
.SYNOPSIS
    Deploys service infrastructure and resources to AWS
.DESCRIPTION
    Deploys or updates service infrastructure in AWS using CloudFormation/SAM templates.
    This includes deploying Lambda functions, configuring authentication resources,
    and setting up other required AWS services.
.PARAMETER None
    This cmdlet does not accept any parameters. It uses system configuration files
    to determine deployment settings.
.EXAMPLE
    Deploy-ServiceAws
    Deploys the service infrastructure using settings from configuration files
.NOTES
    - Requires valid AWS credentials and appropriate permissions
    - Must be run from the AWSTemplates directory
    - Requires system configuration files and SAM templates
    - Will package and upload Lambda functions
    - Will configure the use of authentication resources created with Deploy-AuthsAws
.OUTPUTS
    None
#>
function Deploy-CfLab01ServiceAws {
    [CmdletBinding()]
        param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Deploy-ServiceNodeAws
}

