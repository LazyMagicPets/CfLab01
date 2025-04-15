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

    # Get all lab profiles
    $labprofiles = Get-Accounts

    # Get account configuration
    $accountsConfig = Get-Content -Path "accounts.yaml" -Raw | ConvertFrom-Yaml

    if ($labprofile -eq "all") {
        foreach ($labprofileItem in $labprofiles) {
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
        if ($labprofiles -notcontains $labprofile) {
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