function Deploy-Test {
    param()
        $null = Get-SystemConfig
        $profileName = $script:ProfileName
        Write-Host "ProfileName: $profileName"
}

