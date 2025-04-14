function Remove-TenantsAws {
    [CmdletBinding()]
    param()
    
    try {
        $null = Get-SystemConfig
        $Config = $script:Config

        Write-LzAwsVerbose "Starting tenant removals"
        $TenantsHashTable = $Config.Tenants
        
        if ($TenantsHashTable.Count -eq 0) {
            $errorMessage = @"
Error: No tenants found in system configuration
Function: Remove-TenantsAws
Hints:
  - Check if tenants are defined in systemconfig.yaml
  - Verify the configuration file is properly formatted
  - Ensure you're using the correct configuration file
"@
            throw $errorMessage
        }
        # Process each tenant
        foreach ($TenantKey in $Config.Tenants.Keys) {
            Write-Host "Processing tenant: $TenantKey" -ForegroundColor Yellow
            
            # Remove tenant resources (DynamoDB tables)
            try {
                Remove-TenantResourcesAws -TenantKey $TenantKey
            }
            catch {
                Write-Host "Error removing resources for tenant $TenantKey $($_.Exception.Message)" -ForegroundColor Red
            }

            # Remove tenant stack
            try {
                Remove-TenantAws -TenantKey $TenantKey
            }
            catch {
                Write-Host "Error removing stack for tenant $TenantKey $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-LzAwsVerbose "Finished tenant removals"
        Write-Host "Tenant Removal Complete" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message)
        return $false
    }
    return $true
}