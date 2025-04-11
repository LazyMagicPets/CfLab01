<#
.SYNOPSIS
    Deploys a web application to AWS infrastructure
.DESCRIPTION
    Deploys a specified web application to AWS, handling all necessary AWS resources
    and configurations including S3, CloudFront, and related services.
.PARAMETER ProjectFolder
    The folder containing the web application project (defaults to "WASMApp")
.PARAMETER ProjectName
    The name of the web application project (defaults to "WASMApp")
.EXAMPLE
    Deploy-WebappAws
    Deploys the web application using default project folder and name
.EXAMPLE
    Deploy-WebappAws -ProjectFolder "MyApp" -ProjectName "MyWebApp"
    Deploys the web application from the specified project
.NOTES
    Requires valid AWS credentials and appropriate permissions
    Must be run in the webapp Solution root folder
.OUTPUTS
    None
#>
function Deploy-CfLab01WebappAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile,
        [Parameter(Mandatory = $true)]
        [string]$ProjectFolder
    )
    Deploy-Many -labprofile $labprofile -Function Deploy-WebappSimpleAws -Arguments @{ ProjectFolder=$ProjectFolder}
}

