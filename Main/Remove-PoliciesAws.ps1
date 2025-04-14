<#
.SYNOPSIS
    Removes IAM policies from AWS

.DESCRIPTION
    Removes IAM policies from AWS, cleaning up permissions
    and access controls across the infrastructure.

.EXAMPLE
    Remove-PoliciesAws 
    Removes the specified IAM policies from AWS

.OUTPUTS
    System.Object

.NOTES
    Requires valid AWS credentials and appropriate permissions

.LINK
    Remove-LzAwsCFPoliciesStack

.COMPONENT
    LzAws
#>    
function Remove-PoliciesAws {
    [CmdletBinding()]
    param()	
    Write-Host "Starting CloudFront Policies and Functions stack removal..." -ForegroundColor Yellow
    try {
        Write-Host "Getting system configuration..." -ForegroundColor Yellow
        $null = Get-SystemConfig # find and load the systemconfig.yaml file
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Config = $script:Config

        if ($null -eq $Config) {
            $errorMessage = @"
Error: System configuration is missing Config section
Function: Remove-PoliciesAws
Hints:
  - Check if Config section exists in systemconfig.yaml
  - Verify the configuration file structure
  - Ensure all required configuration sections are present
"@
            throw $errorMessage
        }

        $SystemKey = $Config.SystemKey
        $StackName = $SystemKey + "---policies"

        Write-Host "Removing policies stack: $StackName" -ForegroundColor Yellow
        Write-Host "Using profile: $ProfileName" -ForegroundColor Yellow
        Write-Host "Using region: $Region" -ForegroundColor Yellow

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
        $maxAttempts = 3  # 30 seconds with 10 second intervals
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
            
            Write-Host "Stack deletion in progress... (attempt $($attempt + 1))" -ForegroundColor Yellow
            Start-Sleep -Seconds 10
            $attempt++
        }

        if ($attempt -eq $maxAttempts) {
            throw "Stack deletion timed out after 30 seconds. Check CloudFormation console for details."
        }

        Write-Host "Successfully removed policies stack" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message) -ForegroundColor Red
        return $false
    }
    return $true
}
