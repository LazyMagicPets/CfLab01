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
    Remove-ServiceAws
    Removes the service infrastructure using settings from configuration files
.NOTES
    - Requires valid AWS credentials and appropriate permissions
    - Must be run from the AWSTemplates directory
    - Requires system configuration files
    - Will remove all service-related resources
.OUTPUTS
    None
#>
function Remove-ServiceAws {
    [CmdletBinding()]
    param()	
    Write-LzAwsVerbose "Starting service infrastructure removal"  
    try {
        $SystemConfig = Get-SystemConfig 
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Config = $SystemConfig.Config
        if ($null -eq $Config) {
            $errorMessage = @"
Error: System configuration is missing Config section
Function: Remove-ServiceAws
Hints:
  - Check if Config section exists in systemconfig.yaml
  - Verify the configuration file structure
  - Ensure all required configuration sections are present
"@
            throw $errorMessage
        }

        $SystemKey = $Config.SystemKey
        $StackName = $Config.SystemKey + "---service"
        $ArtifactsBucket = $Config.SystemKey + "---artifacts-" + $Config.SystemSuffix

        # Remove the service stack
        Write-LzAwsVerbose "Removing the stack $StackName using profile $ProfileName" 
        $result = sam delete `
            --stack-name $StackName `
            --region $Region `
            --profile $ProfileName 2>&1

        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            if ($result -match "Stack does not exist") {
                Write-LzAwsVerbose "Stack does not exist. Nothing to remove."
            } else {
                $errorMessage = @"
Error: SAM stack deletion failed
Function: Remove-ServiceAws
Hints:
  - Check AWS CloudFormation console for detailed errors
  - Verify you have required IAM permissions
  - Ensure the stack name is correct
Error Details: $result
"@
                throw $errorMessage
            }
        }

        # Clean up S3 artifacts
        try {
            Write-LzAwsVerbose "Removing S3 artifacts"
            aws s3 rm s3://$ArtifactsBucket/system/ --recursive --profile $ProfileName --region $Region
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to remove S3 artifacts"
            }
        }
        catch {
            $errorMessage = @"
Error: Failed to clean up S3 artifacts
Function: Remove-ServiceAws
Hints:
  - Check if you have permission to delete S3 objects
  - Verify the S3 bucket exists and is accessible
  - Ensure AWS credentials are valid
Error Details: $($_.Exception.Message)
"@
            throw $errorMessage
        }

        Write-Host "Successfully removed service stack" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message)
        return $false
    }
    return $true
} 