function Remove-TenantResourcesAws {
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$true)]
        [string]$TenantKey
    )

    $ProfileName = $script:ProfileName
    $Region = $script:Region
    $Config = $script:Config

    if ($null -eq $Config) {
        $errorMessage = @"
Error: System configuration is required
Function: Remove-TenantResourcesAws
Hints:
  - Check if systemconfig.yaml is loaded
  - Verify the configuration is not null
  - Ensure the configuration file exists
  - Review the configuration loading process
"@
        throw $errorMessage
    }

    if ($null -eq $Region -or $null -eq $ProfileName) {
        $errorMessage = @"
Error: Required AWS configuration is missing
Function: Remove-TenantResourcesAws
Hints:
  - Check if AWS region is set
  - Verify AWS profile name is set
  - Review AWS configuration settings
"@
        throw $errorMessage
    }
   
    # Validate tenant exists in config
    if(-not $Config.Tenants.ContainsKey($TenantKey)) {
        $errorMessage = @"
Error: Tenant '$TenantKey' not found in configuration
Function: Remove-TenantResourcesAws
Hints:
  - Check if the tenant key is correct
  - Verify the tenant is defined in systemconfig.yaml
  - Ensure you're using the correct system configuration
  - Review the tenant configuration structure
"@
        throw $errorMessage
    }

    # Get tenant config
    $KvsEntriesJson = Get-TenantConfig $TenantKey 

    try {
        $KvsEntries = ConvertFrom-Json $KvsEntriesJson -Depth 10
    }
    catch {
        $errorMessage = @"
Error: Failed to convert KvsEntries for '$TenantKey'
Function: Remove-TenantResourcesAws
Hints:
  - Ensure the KeyValueStore is properly configured
  - Review the tenant configuration format
"@
        throw $errorMessage
    }

    # Process each domain in tenant config
    foreach($Property in $KvsEntries.PSObject.Properties) {
        $Domain = $Property.Name
        Write-LzAwsVerbose "Processing $Domain"
        
        # Determine domain level (1 = example.com, 2 = sub.example.com)
        $Level = ($Domain.ToCharArray() | Where-Object { $_ -eq '.' } | Measure-Object).Count
        $KvsEntry = $Property.Value

        # Delete DynamoDB table
        $TableName = $Config.SystemKey + "_" + $TenantKey
        if($Level -eq 2) {
            $TableName += "_" + $KvsEntry.subtenantKey
        }
        
        Write-Host "Deleting DynamoDB table: $TableName" -ForegroundColor Yellow
        try {
            # First check if table exists
            $tableExists = $false
            try {
                $table = Get-DDBTable -TableName $TableName -Region $Region -ProfileName $ProfileName
                if ($table) {
                    $tableExists = $true
                }
            }
            catch {
                if ($_.Exception.Message -like "*ResourceNotFoundException*") {
                    Write-Host "Table $TableName does not exist (already deleted)" -ForegroundColor Green
                    continue
                }
                else {
                    throw
                }
            }

            if ($tableExists) {
                # Delete the table
                Remove-DDBTable -TableName $TableName -Region $Region -ProfileName $ProfileName -Force
                
                # Wait for deletion to complete
                $maxAttempts = 3    # 30 seconds with 10 second intervals
                $attempt = 0
                $deleted = $false
                
                while (-not $deleted -and $attempt -lt $maxAttempts) {
                    $attempt++
                    try {
                        $table = Get-DDBTable -TableName $TableName -Region $Region -ProfileName $ProfileName
                        if (-not $table) {
                            $deleted = $true
                        }
                    }
                    catch {
                        if ($_.Exception.Message -like "*ResourceNotFoundException*") {
                            $deleted = $true
                        }
                        else {
                            throw
                        }
                    }
                    
                    if (-not $deleted) {
                        Write-Host "Waiting for table deletion to complete... (attempt $attempt)" -ForegroundColor Yellow
                        Start-Sleep -Seconds 10
                    }
                }
                
                if ($deleted) {
                    Write-Host "Successfully deleted DynamoDB table: $TableName" -ForegroundColor Green
                }
                else {
                    Write-Host "Timeout waiting for table deletion: $TableName" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "Error deleting DynamoDB table $TableName" -ForegroundColor Red
            Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-LzAwsVerbose "Finished removing tenant resources for $TenantKey"
} 