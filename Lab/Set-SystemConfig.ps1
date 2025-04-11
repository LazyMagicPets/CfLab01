function Set-SystemConfig {
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Write-Host "Setting system config for $labprofile"  
    # Get module root by going up from the Lab directory
    $moduleRoot = Split-Path $PSScriptRoot -Parent

    # Define paths relative to module root
    $templatePath = Join-Path $moduleRoot "Templates/systemconfig.yaml"
    $accountsPath = Join-Path $moduleRoot "accounts.yaml"
    $outputPath = Join-Path $moduleRoot "systemconfig.yaml"

    # Verify files exist
    if (-not (Test-Path $templatePath)) {
        throw "Template file not found: $templatePath"
    }
    if (-not (Test-Path $accountsPath)) {
        throw "Accounts file not found: $accountsPath"
    }

    # Read the files
    $templateContent = Get-Content -Path $templatePath -Raw
    $accountsYaml = Get-Content -Path $accountsPath | ConvertFrom-Yaml

    # Get the account details directly
    $accountDetails = $accountsYaml.Accounts.$labprofile
    
    if (-not $accountDetails) {
        throw "No account found with profile name: $labprofile"
    }

    # Perform replacements using the keys from the specific account
    foreach ($key in $accountDetails.Keys) {
        $placeholder = "{$key}"
        $value = $accountDetails[$key]
        $templateContent = $templateContent.Replace($placeholder, $value)
    }

    # Write the processed content to the output file
    $templateContent | Set-Content -Path $outputPath -Force

    Write-Host "System configuration has been processed and saved to: $outputPath"
}

