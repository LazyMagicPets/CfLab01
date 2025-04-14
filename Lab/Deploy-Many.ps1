function Deploy-Many {
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile,
        [Parameter(Mandatory=$true)]
        [string]$Function,
        [Parameter(Mandatory=$false)]
        [hashtable]$Arguments = @{}
    )
    $labprofiles = Get-Accounts
    $accountsConfig = Get-Content -Path "accounts.yaml" -Raw | ConvertFrom-Yaml
    if($labprofile -eq "all") {
       foreach($labprofileItem in $labprofiles) {
        $accountConfig = $accountsConfig.Accounts[$labprofileItem]
        if ($accountConfig.exclude -eq $true) {
            continue
        }
        Set-SystemConfig -labprofile $labprofileItem
        & $Function @Arguments
       }
    } else 
    {
        if ($labprofiles -notcontains $labprofile) {
            throw "Invalid lab profile: $labprofile."
        }
        Set-SystemConfig -labprofile $labprofile
        & $Function @Arguments
    }
}