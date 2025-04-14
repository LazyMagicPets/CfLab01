<#
.SYNOPSIS
    Removes Node.js service infrastructure and resources from AWS
.DESCRIPTION
    Removes Node.js service infrastructure from AWS including CloudFormation/SAM stacks,
    Lambda functions, and related AWS services.
.PARAMETER None
    This cmdlet does not accept any parameters. It uses system configuration files
    to determine what resources to remove.
.EXAMPLE
    Remove-ServiceNodeAws
    Removes the Node.js service infrastructure using settings from configuration files
.NOTES
    - Requires valid AWS credentials and appropriate permissions
    - Must be run from the AWSTemplates directory
    - Requires system configuration files
    - Will remove all Node.js service-related resources
.OUTPUTS
    None
#>
function Remove-ServiceNodeAws {
    [CmdletBinding()]
    param()	
    Write-Host "Starting Node.js service infrastructure removal..." -ForegroundColor Yellow
    try {
        Write-Host "Getting system configuration..." -ForegroundColor Yellow
        $SystemConfig = Get-SystemConfig 
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Config = $SystemConfig.Config
        if ($null -eq $Config) {
            $errorMessage = @"
Error: System configuration is missing Config section
Function: Remove-ServiceNodeAws
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

        Write-Host "Removing service stack: $StackName" -ForegroundColor Yellow
        Write-Host "Using profile: $ProfileName" -ForegroundColor Yellow
        Write-Host "Using region: $Region" -ForegroundColor Yellow

        # Confirm deletion
        $confirmation = Read-Host "Are you sure you want to delete the stack '$StackName'? This action cannot be undone. (y/n)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled by user." -ForegroundColor Yellow
            return $false
        }

        # Remove the service stack with verbose output
        Write-Host "Starting stack deletion operation (this may take a few minutes)..." -ForegroundColor Yellow
        
        # First check if stack exists
        Write-Host "Checking if stack exists..." -ForegroundColor Yellow
        $stackStatus = aws cloudformation describe-stacks `
            --stack-name $StackName `
            --region $Region `
            --profile $ProfileName 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            if ($stackStatus -match "Stack with id $StackName does not exist") {
                Write-Host "Stack does not exist. Nothing to remove." -ForegroundColor Yellow
                return $true
            }
            throw "Failed to check stack status: $stackStatus"
        }

        # Initiate stack deletion
        Write-Host "Initiating stack deletion..." -ForegroundColor Yellow
        $result = aws cloudformation delete-stack `
            --stack-name $StackName `
            --region $Region `
            --profile $ProfileName 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to initiate stack deletion: $result"
        }

        # Wait for deletion to complete
        Write-Host "Waiting for stack deletion to complete..." -ForegroundColor Yellow
        $maxAttempts = 10  # 5 minutes with 30 second intervals
        $attempt = 0
        
        while ($attempt -lt $maxAttempts) {
            $stackStatus = aws cloudformation describe-stacks `
                --stack-name $StackName `
                --region $Region `
                --profile $ProfileName 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                if ($stackStatus -match "Stack with id $StackName does not exist") {
                    Write-Host "Stack deletion completed successfully." -ForegroundColor Green
                    break
                }
            }
            
            Write-Host "Stack deletion in progress... (attempt $($attempt + 1) of $maxAttempts)" -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            $attempt++
        }

        if ($attempt -eq $maxAttempts) {
            throw "Stack deletion timed out after 5 minutes. Check CloudFormation console for details."
        }

        Write-Host "Stack deletion completed. Cleaning up S3 artifacts..." -ForegroundColor Yellow

        # Clean up S3 artifacts
        try {
            aws s3 rm s3://$ArtifactsBucket/system/ --recursive --profile $ProfileName --region $Region
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to remove S3 artifacts"
            }
        }
        catch {
            $errorMessage = @"
Error: Failed to clean up S3 artifacts
Function: Remove-ServiceNodeAws
Hints:
  - Check if you have permission to delete S3 objects
  - Verify the S3 bucket exists and is accessible
  - Ensure AWS credentials are valid
Error Details: $($_.Exception.Message)
"@
            throw $errorMessage
        }

        Write-Host "Successfully removed Node.js service stack" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message) -ForegroundColor Red
        return $false
    }
    return $true
}
