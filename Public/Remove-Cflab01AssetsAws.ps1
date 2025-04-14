<#
.SYNOPSIS
    Removes system and tenant assets from AWS S3 buckets
.DESCRIPTION
    Removes assets from the Tenancies solution from AWS S3 buckets for both system-level and tenant-specific assets.
    Processes tenant configurations to determine appropriate bucket names and asset deployments based on domain structure.
    Supports both single-level tenant domains (tenant.example.com) and two-level tenant domains (subtenant.tenant.example.com).
.PARAMETER None
    This cmdlet does not accept parameters directly, but reads from system configuration
.EXAMPLE
    Remove-Cflab01AssetsAws
    Removes all system and tenant assets based on configuration
.NOTES
    - Must be run from the Tenancy Solution root folder
    - Tenant projects must follow naming convention: [tenant][-subtenant]
    - Do not prefix project names with system key
    - Primarily intended as a development tool
.OUTPUTS
    None
#>

function Remove-CfLab01AssetsAws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Remove-AssetsAws
}