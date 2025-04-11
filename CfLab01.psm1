# LzLab01.psm1
# This is a PowerShell module that provides AWS infrastructure management functionality.
# It handles module initialization, verbosity settings, and AWS module dependencies.

# Module-scoped variables to track state
$script:LzAwsVerbosePreference = $script:LzAwsVerbosePreference ?? "SilentlyContinue"
$script:ModulesInitialized = $false                  # Tracks if modules are initialized
$ErrorView = "CategoryView"                          # Suppress call stack display

# Function to set module verbosity level
function Set-LzLab01Verbosity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Continue", "SilentlyContinue", "Stop", "Inquire")]
        [string]$Preference
    )
    
    $script:LzAwsVerbosePreference = $Preference
    # Add immediate verification
    if ($script:LzAwsVerbosePreference -ne $Preference) {
        Write-Warning "Failed to set verbosity preference"
        return
    }
    Write-Host "VERBOSE: LzLab01 module verbosity set to: $Preference" -ForegroundColor Yellow
}

# Function to get current verbosity setting
function Get-LzLab01Verbosity {
    [CmdletBinding()]
    param()
    
    return $script:LzAwsVerbosePreference
}

# Function to remove any existing AWS modules to avoid conflicts
function Remove-ConflictingAWSModules {
    [CmdletBinding()]
    param()

    Write-Verbose "Removing any conflicting AWS modules from session..."
    
    # Remove AWS modules from current session
    Get-Module | Where-Object {
        $_.Name -like 'AWS*' -or 
        $_.Name -like 'AWSPowerShell*' -or 
        $_.Name -like 'AWS.Tools.*'
    } | ForEach-Object {
        Write-Verbose "Removing module from session: $($_.Name)"
        Remove-Module -Name $_.Name -Force -ErrorAction SilentlyContinue
    }

    # Force garbage collection
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Verbose "Finished removing AWS modules from session"
}

# Define required AWS modules and their minimum versions
$script:ModuleRequirements = [ordered]@{
    'powershell-yaml' = '0.4.2'
    'AWS.Tools.Common' = '4.1.748'
    'AWS.Tools.Installer' = '1.0.2.5'   
    'AWS.Tools.SecurityToken' = '4.1.748'
    'AWS.Tools.S3' = '4.1.748'
    'AWS.Tools.CloudFormation' = '4.1.748'
    'AWS.Tools.CloudFrontKeyValueStore' = '4.1.748'
    'AWS.Tools.DynamoDBv2' = '4.1.136'
}

# Function to import a single AWS module
function Import-SingleAWSModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        [version]$MinimumVersion
    )

    try {
        Write-Verbose "Importing module: $ModuleName"
        
        # Check if module needs to be installed/updated
        $installedModule = Get-Module -Name $ModuleName -ListAvailable | 
                          Sort-Object Version -Descending | 
                          Select-Object -First 1

        if (-not $installedModule -or $installedModule.Version -lt $MinimumVersion) {
            Write-Verbose "Installing/updating $ModuleName to minimum version $MinimumVersion..."
            Install-Module -Name $ModuleName -MinimumVersion $MinimumVersion -Force -AllowClobber -Scope CurrentUser
        }

        Import-Module -Name $ModuleName -MinimumVersion $MinimumVersion -Force -DisableNameChecking
        Write-Verbose "Successfully imported $ModuleName"
        return $true
    }
    catch {
        Write-Error "Failed to import module $ModuleName. Error: $_"
        return $false
    }
}

# Function to initialize all required AWS modules
function Initialize-LzLab01Modules {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    if ($script:ModulesInitialized -and -not $Force) { 
        Write-Verbose "Modules already initialized"
        return 
    }

    Remove-ConflictingAWSModules

    Write-Verbose "Importing required modules..."
    $failedImports = @()
    foreach ($module in $script:ModuleRequirements.Keys) {
        if (-not (Import-SingleAWSModule -ModuleName $module -MinimumVersion $script:ModuleRequirements[$module])) {
            $failedImports += $module
        }
    }

    if ($failedImports.Count -gt 0) {
        $script:ModulesInitialized = $false
        $failedList = $failedImports -join ", "
        throw "Failed to import the following required modules: $failedList"
    }

    $script:ModulesInitialized = $true
    Write-Verbose "AWS modules initialized successfully"
}

# Function to reset module state
function Reset-LzLab01Modules {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Resetting AWS modules..."
    $script:ModulesInitialized = $false
    Remove-ConflictingAWSModules
    Initialize-LzLab01Modules -Force
    Write-Verbose "AWS modules reset completed"
}

# Initialize modules when the module is imported
try {
    Initialize-LzLab01Modules
}
catch {
    Write-Error "Failed to initialize LzLab01 module: $_"
    throw
}

# Set up module structure and import functions
$FunctionsPath = $PSScriptRoot
$LibraryPath = Join-Path $FunctionsPath "Library"
$PublicPath = Join-Path $FunctionsPath "Public"
$MainPath = Join-Path $FunctionsPath "Main"
$LabPath = Join-Path $FunctionsPath "Lab"

# Create Library and Public directories if needed
if (!(Test-Path $LibraryPath)) {
    New-Item -ItemType Directory -Path $LibraryPath -Force | Out-Null
    Write-Verbose "Created Library directory at $LibraryPath"
}
if (!(Test-Path $PublicPath)) {
    New-Item -ItemType Directory -Path $PublicPath -Force | Out-Null
    Write-Verbose "Created Public directory at $PublicPath"
}
if (!(Test-Path $MainPath)) {
    New-Item -ItemType Directory -Path $MainPath -Force | Out-Null
    Write-Verbose "Created Main directory at $MainPath"
}
if (!(Test-Path $LabPath)) {
    New-Item -ItemType Directory -Path $LabPath -Force | Out-Null
    Write-Verbose "Created Lab directory at $LabPath"
}
# Import all public and Library functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Library = @(Get-ChildItem -Path $PSScriptRoot\Library\*.ps1 -ErrorAction SilentlyContinue)
$Main = @(Get-ChildItem -Path $PSScriptRoot\Main\*.ps1 -ErrorAction SilentlyContinue)
$Lab = @(Get-ChildItem -Path $PSScriptRoot\Lab\*.ps1 -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Library + $Main + $Lab)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

# Function to initialize help documentation
function Initialize-LzLab01Help {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    try {
        Write-Verbose "Initializing help system..."
        
        $helpPath = Join-Path $PSScriptRoot "en-US"
        
        if (!(Test-Path $helpPath)) {
            New-Item -ItemType Directory -Path $helpPath -Force | Out-Null
        }

        # Create about help file
        $aboutHelpPath = Join-Path $helpPath "about_LzLab01.help.txt"
        @"
TOPIC
    about_LzLab01

SHORT DESCRIPTION
    AWS infrastructure management tools

LONG DESCRIPTION
    This module provides cmdlets for managing AWS infrastructure deployments.
    
    The following cmdlets are included:
    - Deploy-* cmdlets for deploying various AWS resources
    - Get-* cmdlets for retrieving information
"@ | Set-Content $aboutHelpPath

        Write-Verbose "Help system initialized successfully"
    }
    catch {
        Write-Error "Failed to initialize help system: $_"
    }
}

# Initialize help system
try {
    Initialize-LzLab01Help
}
catch {
    Write-Warning "Failed to initialize help system: $_"
}

# Export public functions and aliases
Export-ModuleMember -Function $Public.BaseName

$AliasesToExport = @()
if ($AliasesToExport) {
    Export-ModuleMember -Alias $AliasesToExport
}

# Clean up when module is removed
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "Cleaning up AWS modules..."
    Remove-ConflictingAWSModules
}

# At the bottom of the file
Export-ModuleMember -Function @(
    'Set-LzLab01Verbosity',
    'Get-LzLab01Verbosity'
    # ... other functions ...
)