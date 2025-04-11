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
function Deploy-WebappSimpleAws {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory = $true)]
        [string]$ProjectFolder
    )
    try {
        Write-LzAwsVerbose "Starting web application deployment"

        $null = Get-SystemConfig
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Account = $script:Account      
        $Config = $script:Config
        $SystemKey = $Config.SystemKey
        $SystemSuffix = $Config.SystemSuffix

        $LocalFolderPath = "./$ProjectFolder/wwwroot"

        # Verify apppublish.json exists and is valid
        $AppPublishPath = "./$ProjectFolder/apppublish.json"
        if (-not (Test-Path $AppPublishPath)) {
            $errorMessage = @"
Error: apppublish.json not found
Function: Deploy-WebappAws
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
Function: Deploy-WebappAws
Hints:
  - Check if AppName is defined in apppublish.json
  - Verify the JSON format is valid
  - Ensure all required fields are present
"@
            throw $errorMessage
        }

        $AppName = $AppPublish.AppName
        $BucketName = "$SystemKey---webapp-$AppName-$SystemSuffix"

        Write-LzAwsVerbose "Creating S3 bucket: $BucketName"
        New-LzAwsS3Bucket -BucketName $BucketName -Region $Region -Account $Account -BucketType "WEBAPP" -ProfileName $ProfileName
        
        # Perform the sync operation
        $S3KeyPrefix = "wwwroot"
        $SyncCommand = "aws s3 sync `"$LocalFolderPath`" `"s3://$BucketName/$S3KeyPrefix`" --delete --region $Region --profile `"$ProfileName`""
        Write-LzAwsVerbose "Running sync command: $SyncCommand"

        $SyncResult = Invoke-Expression $SyncCommand 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $errorMessage = @"
Error: Failed to sync files to S3
Function: Deploy-WebappAws
Hints:
  - Check if you have permission to write to the S3 bucket
  - Verify the local files exist and are accessible
  - Ensure AWS credentials are valid
Error Details: Sync operation failed with exit code $exitCode
Command Output: $($SyncResult | Out-String)
"@
            throw $errorMessage
        }
        Write-Host "Successfully deployed web application" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message)
        return $false
    }
    return $true
}

