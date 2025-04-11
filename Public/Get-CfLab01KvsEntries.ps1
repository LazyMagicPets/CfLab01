<#
.SYNOPSIS
    Reads the KVS entries for the current account
.DESCRIPTION
    Reads the KVS entries for the current account
.EXAMPLE
    Get-KvsEntries
.EXAMPLE
    Get-KvsEntries
.NOTES
    Requires valid AWS credentials and appropriate permissions
    Must be run in the webapp Solution root folder
.OUTPUTS
    None
#>
function Get-CfLab01KvsEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    ) 
    Deploy-Many -labprofile $labprofile -Function Get-KvsEntries 
}