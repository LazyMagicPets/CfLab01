<#
.SYNOPSIS
    Deploys authentication configurations to AWS
.DESCRIPTION
    Deploys or updates authentication and authorization configurations
    in AWS, including Cognito User Pools, Identity Pools, and related resources.
.EXAMPLE
    Deploy-AuthsAws
    Deploys the authentication configurations defined in the system config
.NOTES
    Requires valid AWS credentials and appropriate permissions
.OUTPUTS
    System.Object
#>
function Deploy-CfLab01AuthsAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Deploy-AuthsAws
}