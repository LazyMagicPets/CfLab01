<#
.SYNOPSIS
    Removes a web application from AWS infrastructure
.DESCRIPTION
    Removes a specified web application from AWS, including its S3 bucket and contents.
.PARAMETER ProjectFolder
    The folder containing the web application project (defaults to "WASMApp")
.PARAMETER ProjectName
    The name of the web application project (defaults to "WASMApp")
.EXAMPLE
    Remove-WebappSimpleAws
    Removes the web application using default project folder and name
.EXAMPLE
    Remove-WebappSimpleAws -ProjectFolder "MyApp" -ProjectName "MyWebApp"
    Removes the web application from the specified project
.NOTES
    Requires valid AWS credentials and appropriate permissions
    Must be run in the webapp Solution root folder
.OUTPUTS
    None
#>
function Remove-WebappSimpleAws {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory = $true)]
        [string]$ProjectFolder
    )
    try {
        Write-LzAwsVerbose "Starting web application removal"

        $null = Get-SystemConfig
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Account = $script:Account      
        $Config = $script:Config
        $SystemKey = $Config.SystemKey
        $SystemSuffix = $Config.SystemSuffix

        # Verify apppublish.json exists and is valid
        $AppPublishPath = "./$ProjectFolder/apppublish.json"
        if (-not (Test-Path $AppPublishPath)) {
            $errorMessage = @"
Error: apppublish.json not found
Function: Remove-WebappSimpleAws
Hints:
  - Check if apppublish.json exists in: $AppPublishPath
  - Verify the project folder is correct
  - Ensure the configuration file is present
"@
            throw $errorMessage
        }

        $AppPublish = Get-Content -Path $AppPublishPath -Raw | ConvertFrom-Json
        if ($null -eq $AppPublish.AppName) {
            $errorMessage = @"
Error: Invalid apppublish.json format
Function: Remove-WebappSimpleAws
Hints:
  - Check if AppName is defined in apppublish.json
  - Verify the JSON format is valid
  - Ensure all required fields are present
"@
            throw $errorMessage
        }

        $AppName = $AppPublish.AppName
        $BucketName = "$SystemKey---webapp-$AppName-$SystemSuffix"

        Write-LzAwsVerbose "Removing S3 bucket: $BucketName"
        Remove-LzAwsS3Bucket -BucketName $BucketName -Region $Region -Account $Account -ProfileName $ProfileName
        
        Write-Host "Successfully removed web application" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message)
        return $false
    }
    return $true
}
