function Deploy-Test {
    param(
        [Parameter(Mandatory=$true)]
        [string]$yada
    )
    Get-SystemConfig
    Write-Host "Deploy-Test yada $yada"
    
}

