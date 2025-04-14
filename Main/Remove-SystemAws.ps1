<#
.SYNOPSIS
    Removes system-wide AWS infrastructure
.DESCRIPTION
    Removes core system infrastructure components from AWS, including
    the main system stack and system resources.
.PARAMETER None
    This cmdlet does not accept parameters directly, but reads from system configuration
.EXAMPLE
    Remove-SystemAws
    Removes the system infrastructure based on configuration in systemconfig.yaml
.NOTES
    - Must be run from the Tenancy Solution root folder
    - Requires valid AWS credentials and appropriate permissions
    - Uses AWS CloudFormation for stack removal
.OUTPUTS
    None
#>
function Remove-SystemAws {
    [CmdletBinding()]
    param()    
    Write-Host "Starting system infrastructure removal..." -ForegroundColor Yellow
    try {
        Write-Host "Getting system configuration..." -ForegroundColor Yellow
        $null = Get-SystemConfig 
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Config = $script:Config
        $SystemKey = $Config.SystemKey
        $SystemSuffix = $Config.SystemSuffix
        
        $StackName = $SystemKey + "---system"
        Write-Host "Removing system stack: $StackName" -ForegroundColor Yellow
        Write-Host "Using profile: $ProfileName" -ForegroundColor Yellow
        Write-Host "Using region: $Region" -ForegroundColor Yellow

        # Confirm deletion
        $confirmation = Read-Host "Are you sure you want to delete the system stack '$StackName'? This action cannot be undone. (y/n)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled by user." -ForegroundColor Yellow
            return $false
        }

        # First check if stack exists
        Write-Host "Checking if stack exists..." -ForegroundColor Yellow
        $stackStatus = aws cloudformation describe-stacks `
            --stack-name $StackName `
            --region $Region `
            --profile $ProfileName 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            if ($stackStatus -match "Stack with id $StackName does not exist") {
                Write-Host "Stack does not exist. Nothing to remove." -ForegroundColor Yellow
            } else {
                throw "Failed to check stack status: $stackStatus"
            }
        } else {
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
        }

        # Remove system resources
        Write-Host "Removing system resources..." -ForegroundColor Yellow
        Remove-SystemResourcesAws

        Write-Host "Successfully removed system infrastructure" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message) -ForegroundColor Red
        return $false
    }
    return $true
}
