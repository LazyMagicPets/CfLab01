<#
.SYNOPSIS
    Removes authentication configurations from AWS
.DESCRIPTION
    Removes authentication and authorization configurations
    from AWS, including Cognito User Pools, Identity Pools, and related resources.
.EXAMPLE
    Remove-Cflab01AuthsAws
    Removes the authentication configurations defined in the system config
.NOTES
    Requires valid AWS credentials and appropriate permissions
.OUTPUTS
    System.Object
#>
function Remove-Cflab01AuthsAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Remove-AuthsAws
}