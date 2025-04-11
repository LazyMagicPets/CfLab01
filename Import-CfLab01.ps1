# Find and install the LzAws module
# This script allows you to load different versions of the LzAws 
# powershell module for different system implementations.
#
# Also, since this script removes the module if it already exists,
# you can run this script to pick up any changes you have made to 
# the scripts in the module.

# First remove existing module
Remove-Module Cflab01 -Force -ErrorAction SilentlyContinue

# Get current directory's full path
$currentPath = (Get-Location).Path

# Keep searching until we reach the root
while ($currentPath -ne "") {
    # Check for direct LzAws folder
    $directPath = Join-Path $currentPath "LzLab01\CfLab01.psm1"
    # Check for LazyMagic/LzAws path
    $nestedPath = Join-Path $currentPath "LazyMagic\CfLab01\CfLab01.psm1"

    if (Test-Path $directPath) {
        Write-Host "Importing CfLab01 from $directPath"
        Import-Module $directPath
        break;
    }
    elseif (Test-Path $nestedPath) {
        Write-Host "Importing CfLab01 from $nestedPath"
        Import-Module $nestedPath
        break;
    }
    
    # Move up one directory
    $currentPath = Split-Path $currentPath -Parent
}

if (-not (Get-Module CfLab01)) {
    Write-Error "Could not find CfLab module in parent directories"
}