function Deploy-Many {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile,
        [Parameter(Mandatory=$true)]
        [string]$Function,
        [Parameter(Mandatory=$false)]
        [hashtable]$Arguments = @{}
    )

    # Get all lab profiles in order from accounts.yaml
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    $accountsPath = Join-Path $moduleRoot "accounts.yaml"
    $accountsYaml = Get-Content -Path $accountsPath -Raw
    $accountsConfig = $accountsYaml | ConvertFrom-Yaml

    # Extract account names in order from the raw YAML
    $orderedAccounts = @()
    $accountsYaml -split "`n" | ForEach-Object {
        if ($_ -match '^\s*(\w+-\d+):') {
            $orderedAccounts += $Matches[1]
        }
    }

    if ($labprofile -eq "all") {
        foreach ($labprofileItem in $orderedAccounts) {
            # Skip if excluded
            if ($accountsConfig.Accounts[$labprofileItem].exclude) {
                Write-Host "Skipping $labprofileItem (excluded in accounts.yaml)" -ForegroundColor Yellow
                continue
            }

            Write-Host "`nProcessing $labprofileItem..." -ForegroundColor Cyan
            Set-SystemConfig -labprofile $labprofileItem
            & $Function @Arguments
        }
    } else {
        # Validate the specified profile exists
        if ($orderedAccounts -notcontains $labprofile) {
            throw "Lab profile '$labprofile' not found in accounts.yaml"
        }

        # Skip if excluded
        if ($accountsConfig.Accounts[$labprofile].exclude) {
            Write-Host "Skipping $labprofile (excluded in accounts.yaml)" -ForegroundColor Yellow
            return
        }

        Write-Host "`nProcessing $labprofile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $labprofile
        & $Function @Arguments
    }
}