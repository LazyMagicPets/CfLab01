<#
.SYNOPSIS
    Creates an admin user in a user pool
.DESCRIPTION
    Creates an admin user in the user pool if it doesn't exist

.PARAMETER None
    This cmdlet does not accept parameters directly, but reads from system configuration
.EXAMPLE
    Set-Admin
    Creates an admin user in the user pool
.NOTES
    - Must be run from the Tenancy Solution root folder
.OUTPUTS
    None
#>

function Set-CfLab01Admin {
    [CmdletBinding()]
        param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    ) 

    Deploy-Many -labprofile $labprofile -Function Set-Admin
}