<#
.SYNOPSIS
    Removes system and tenant assets from AWS S3 buckets
.DESCRIPTION
    Removes assets from AWS S3 buckets for both system-level and tenant-specific assets.
    Processes tenant configurations to determine appropriate bucket names and asset removals based on domain structure.
    Supports both single-level tenant domains (tenant.example.com) and two-level tenant domains (subtenant.tenant.example.com).
.PARAMETER None
    This cmdlet does not accept parameters directly, but reads from system configuration
.EXAMPLE
    Remove-AssetsAws
    Removes all system and tenant assets based on configuration
.NOTES
    - Must be run from the Tenancy Solution root folder
    - Tenant projects must follow naming convention: [tenant][-subtenant]
    - Do not prefix project names with system key
    - Primarily intended as a development tool
.OUTPUTS
    None
#>

function Remove-AssetsAws {
    [CmdletBinding()]
    param()

    try {
        $null = Get-SystemConfig
        $Region = $script:Region
        $Account = $script:Account    
        $ProfileName = $script:Config.Profile
        $Config = $script:Config

        # Remove system assets
        $BucketName = $Config.SystemKey + "---assets-" + $Config.SystemSuffix
        Write-Host "Checking if system assets bucket exists: $BucketName"
        $bucketExists = aws s3api head-bucket --bucket $BucketName --region $Region --profile $ProfileName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Removing system assets from bucket: $BucketName using profile: $ProfileName"
            Remove-LzAwsS3Bucket -BucketName $BucketName -Region $Region -Account $Account -ProfileName $ProfileName
        } else {
            Write-Host "System assets bucket does not exist, skipping removal"
        }

        # Remove tenant assets
        Write-Host "Processing tenant configurations..."
        $Tenants = $Config.Tenants
        foreach($TenantKey in $Tenants.Keys) {
            Write-Host "Processing tenant: $TenantKey"
            $TenantConfigJson = Get-TenantConfig $TenantKey
            $KvsEntries = $TenantConfigJson | ConvertFrom-Json -Depth 10

            # Process the tenant and subtenants for the tenant
            foreach($Prop in $KvsEntries.PSObject.Properties) {
                $Domain = $Prop.Name
                $KvsEntry = $Prop.Value
                $Tenant = $KvsEntry.tenantKey
                $Subtenant = $KvsEntry.subtenantKey
                $DomainParts = $Domain.Split('.') 
                $DomainPartsCount = $DomainParts.Count

                # Determine tenancy project name and level based on domain structure
                $TenancyProject = ""
                $TenantLevel = 0
                
                if($DomainPartsCount -eq 2) {
                    # Domain format: tenant.example.com
                    $TenancyProject = $Tenant
                    $TenantLevel = 1
                } 
                elseif($DomainPartsCount -eq 3) {
                    # Domain format: subtenant.tenant.example.com
                    $TenancyProject = $Tenant + "-" + $Subtenant
                    $TenantLevel = 2
                } 
                else {
                    $errorMessage = @"
Error: Invalid domain format for tenant '$TenantKey'
Function: Remove-AssetsAws
Hints:
- Domain must be in format: tenant.example.com or subtenant.tenant.example.com
- Check tenant configuration in systemconfig.yaml
- Verify domain structure matches expected format
Domain: $Domain
"@
                    throw $errorMessage
                }

                Write-Host "Processing domain configuration:"
                Write-Host "Domain: $Domain"
                Write-Host "Tenant: $Tenant"
                Write-Host "Subtenant: $Subtenant"
                Write-Host "Tenant Level: $TenantLevel"

                # Remove Tenant Asset Bucket for matching behaviors
                $Behaviors = $KvsEntry.Behaviors
                foreach($Behavior in $Behaviors) {
                    $AssetType = $Behavior[1]
                    if($AssetType -ne "assets") {
                        continue
                    }
                    
                    $BehaviorLevel = $Behavior[4]
                    if($BehaviorLevel -ne $TenantLevel) {
                        continue
                    }

                    $BucketName = Get-AssetName $KvsEntry $Behavior $false
                    Write-Host "Checking if tenant assets bucket exists: $BucketName"
                    $bucketExists = aws s3api head-bucket --bucket $BucketName --region $Region --profile $ProfileName 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Removing tenant assets for project: $TenancyProject from bucket: $BucketName using profile: $ProfileName"
                        Remove-LzAwsS3Bucket -BucketName $BucketName -Region $Region -Account $Account -ProfileName $ProfileName
                    } else {
                        Write-Host "Tenant assets bucket does not exist, skipping removal"
                    }
                }
            }
        }
    } 
    catch {
        Write-Host ($_.Exception.Message)
        return $false
    }
    Write-LzAwsVerbose "Finished removing all assets"
    return $true
}
