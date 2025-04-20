<#
.SYNOPSIS
    Gets the status of the tenant CloudFormation stack
.DESCRIPTION
    Checks the status of the CloudFormation stack named 'lzm-mp--tenant' in the current AWS profile
.EXAMPLE
    Get-TenantStatus
    Returns the status of the tenant stack in the current AWS profile
.OUTPUTS
    PSCustomObject containing stack status information
#>
function Get-TenantStatus {
    [CmdletBinding()]
    param()

    $stackName = "lzm-mp--tenant"
    
    try {
        # Get region from system config
        $systemConfig = Get-Content -Path (Join-Path (Split-Path $PSScriptRoot -Parent) "systemconfig.yaml") -Raw | ConvertFrom-Yaml
        $region = $systemConfig.region
        
        # Set AWS region
        Set-DefaultAWSRegion -Region $region
        
        $stack = Get-CFNStack -StackName $stackName -ErrorAction Stop
        return [PSCustomObject]@{
            StackName = $stack.StackName
            StackId = $stack.StackId
            Status = $stack.StackStatus
            CreationTime = $stack.CreationTime
            LastUpdatedTime = $stack.LastUpdatedTime
        }
    }
    catch {
        if ($_.Exception.Message -like "*does not exist*") {
            Write-Host "Stack '$stackName' does not exist" -ForegroundColor Yellow
            return $null
        }
        Write-Error "Error checking stack status: $_"
        throw $_
    }
}
