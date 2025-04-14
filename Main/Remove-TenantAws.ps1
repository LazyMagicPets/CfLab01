<#
.SYNOPSIS
    Removes a tenant configuration from AWS
.DESCRIPTION
    Removes a tenant's configuration and resources in AWS environment,
    including necessary IAM roles, policies, and related resources.
.PARAMETER TenantKey
    The unique identifier for the tenant that matches a tenant defined in SystemConfig.yaml
.EXAMPLE
    Remove-TenantAws -TenantKey "tenant123"
    Removes the specified tenant configuration from AWS
.NOTES
    Requires valid AWS credentials and appropriate permissions
    The tenantKey must match a tenant defined in the SystemConfig.yaml file
.OUTPUTS
    None
#>
function Remove-TenantAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TenantKey
    )

    try {
        Write-LzAwsVerbose "Removing tenant stack"

        $null = Get-SystemConfig 
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Config = $script:Config
        $SystemKey = $Config.SystemKey

        $StackName = $SystemKey + "-" + $TenantKey + "--tenant"

        Write-Host "Deleting the stack $StackName"
        $result = aws cloudformation delete-stack `
            --stack-name $StackName `
            --region $Region `
            --profile $ProfileName 2>&1

        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $errorMessage = @"
Error: Failed to delete CloudFormation stack for tenant '$TenantKey'
Function: Remove-TenantAws
Hints:
  - Check AWS CloudFormation console for detailed errors
  - Verify you have required IAM permissions
  - Ensure the stack exists
Error Details: Stack deletion failed with exit code $exitCode
Command Output: $($result | Out-String)
"@
            throw $errorMessage
        }

        Write-LzAwsVerbose "Stack deletion initiated successfully for $TenantKey"
    }
    catch {
        Write-Host ($_.Exception.Message)
        return $false
    }
    return $true
}
