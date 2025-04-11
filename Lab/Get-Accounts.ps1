function Get-Accounts {
    param()

    # Get module root by going up from the Lab directory
    $moduleRoot = Split-Path $PSScriptRoot -Parent

    # Define path to accounts file
    $accountsPath = Join-Path $moduleRoot "accounts.yaml"

    # Verify file exists
    if (-not (Test-Path $accountsPath)) {
        throw "Accounts file not found: $accountsPath"
    }

    # Read and parse the YAML
    $accountsYaml = Get-Content -Path $accountsPath | ConvertFrom-Yaml

    # Return the account names (keys from the Accounts section)
    return $accountsYaml.Accounts.Keys
}

