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

    # Read the raw YAML content
    $accountsYaml = Get-Content -Path $accountsPath -Raw

    # Extract account names in order from the raw YAML
    $orderedAccounts = @()
    $accountsYaml -split "`n" | ForEach-Object {
        if ($_ -match '^\s*(\w+-\d+):') {
            $orderedAccounts += $Matches[1]
        }
    }

    # Return the ordered account names
    return $orderedAccounts
}

