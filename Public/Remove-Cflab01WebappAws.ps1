<#
.SYNOPSIS
    Removes a web application from AWS infrastructure
.DESCRIPTION
    Removes a specified web application from AWS, handling all necessary AWS resources
    and configurations including S3, CloudFront, and related services.
.PARAMETER ProjectFolder
    The folder containing the web application project (defaults to "WASMApp")
.PARAMETER ProjectName
    The name of the web application project (defaults to "WASMApp")
.EXAMPLE
    Remove-Cflab01WebappAws
    Removes the web application using default project folder and name
.EXAMPLE
    Remove-Cflab01WebappAws -ProjectFolder "MyApp" -ProjectName "MyWebApp"
    Removes the web application from the specified project
.NOTES
    Requires valid AWS credentials and appropriate permissions
    Must be run in the webapp Solution root folder
.OUTPUTS
    None
#>
function Remove-CfLab01WebappAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile,
        [Parameter(Mandatory = $true)]
        [string]$ProjectFolder
    )
    Deploy-Many -labprofile $labprofile -Function Remove-WebappSimpleAws -Arguments @{ ProjectFolder=$ProjectFolder}
}