<#
.SYNOPSIS
    Removes system resources from AWS
.DESCRIPTION
    Removes system resources created by Deploy-SystemResourcesAws, including
    the DynamoDB table used for system configuration.
.PARAMETER None
    This cmdlet does not accept parameters directly, but reads from system configuration
.EXAMPLE
    Remove-SystemResourcesAws
    Removes the system resources based on configuration in systemconfig.yaml
.NOTES
    - Must be run from the Tenancy Solution root folder
    - Requires valid AWS credentials and appropriate permissions
    - Uses AWS CLI for resource removal
.OUTPUTS
    None
#>
function Remove-SystemResourcesAws {
    [CmdletBinding()]
    param()    
    Write-Host "Starting system resources removal..." -ForegroundColor Yellow
    try {
        Write-Host "Getting system configuration..." -ForegroundColor Yellow
        $null = Get-SystemConfig 
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Config = $script:Config
        $SystemKey = $Config.SystemKey

        # Remove DynamoDB table
        $TableName = $SystemKey
        Write-Host "Removing DynamoDB table: $TableName" -ForegroundColor Yellow

        # Check if table exists
        $tableExists = aws dynamodb describe-table `
            --table-name $TableName `
            --region $Region `
            --profile $ProfileName 2>&1

        if ($LASTEXITCODE -eq 0) {
            # Delete the table
            Write-Host "Deleting DynamoDB table..." -ForegroundColor Yellow
            $result = aws dynamodb delete-table `
                --table-name $TableName `
                --region $Region `
                --profile $ProfileName 2>&1

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to delete DynamoDB table: $result"
            }

            # Wait for deletion to complete
            Write-Host "Waiting for table deletion to complete..." -ForegroundColor Yellow
            $maxAttempts = 3  # 30 seconds with 10 second intervals
            $attempt = 0
            
            while ($attempt -lt $maxAttempts) {
                $tableStatus = aws dynamodb describe-table `
                    --table-name $TableName `
                    --region $Region `
                    --profile $ProfileName 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    if ($tableStatus -match "ResourceNotFoundException") {
                        Write-Host "Table deletion completed successfully." -ForegroundColor Green
                        break
                    }
                }
                
                Write-Host "Table deletion in progress... (attempt $($attempt + 1))" -ForegroundColor Yellow
                Start-Sleep -Seconds 30
                $attempt++
            }

            if ($attempt -eq $maxAttempts) {
                throw "Table deletion timed out after 30 seconds. Check AWS console for details."
            }
        } else {
            Write-Host "DynamoDB table does not exist. Nothing to remove." -ForegroundColor Yellow
        }

        Write-Host "Successfully removed system resources" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message) -ForegroundColor Red
        return $false
    }
    return $true
} 