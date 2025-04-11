function Write-LzAwsVerbose {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message
    )
    
    # Force read from script scope
    $current = $script:LzAwsVerbosePreference
    if ($current -eq 'Continue') {
        Write-Host "VERBOSE: $Message" -ForegroundColor Yellow
    }
}