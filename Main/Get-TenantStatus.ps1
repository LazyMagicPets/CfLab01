<#
.SYNOPSIS
    Gets the status of the tenant CloudFormation stack
.DESCRIPTION
    Checks the status of the CloudFormation stack named 'lzm-mp--tenant' in the current AWS profile
    and displays the status with appropriate color coding.
.PARAMETER profile
    The AWS profile name to display in the output
.EXAMPLE
    Get-TenantStatus -profile "cflab-01"
    Displays the status of the tenant stack in the current AWS profile
#>
function Get-TenantStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$profile
    )

    $stackName = "lzm-mp--tenant"
    
    try {
        # Get region from system config
        $systemConfig = Get-Content -Path (Join-Path (Split-Path $PSScriptRoot -Parent) "systemconfig.yaml") -Raw | ConvertFrom-Yaml
        $region = $systemConfig.region
        
        # Set AWS region
        Set-DefaultAWSRegion -Region $region
        
        $stack = Get-CFNStack -StackName $stackName -ErrorAction Stop
        
        # Display status with appropriate color
        switch ($stack.StackStatus) {
            "CREATE_COMPLETE" { 
                Write-Host "$profile returned with a status of CREATE_COMPLETE" -ForegroundColor Green
            }
            "CREATE_IN_PROGRESS" { 
                Write-Host "$profile returned with a status of CREATE_IN_PROGRESS" -ForegroundColor Yellow
            }
            "CREATE_FAILED" { 
                Write-Host "$profile returned with a status of CREATE_FAILED" -ForegroundColor Red
            }
            "UPDATE_COMPLETE" { 
                Write-Host "$profile returned with a status of UPDATE_COMPLETE" -ForegroundColor Green
            }
            "UPDATE_IN_PROGRESS" { 
                Write-Host "$profile returned with a status of UPDATE_IN_PROGRESS" -ForegroundColor Yellow
            }
            "UPDATE_FAILED" { 
                Write-Host "$profile returned with a status of UPDATE_FAILED" -ForegroundColor Red
            }
            "DELETE_COMPLETE" { 
                Write-Host "$profile returned with a status of DELETE_COMPLETE" -ForegroundColor Green
            }
            "DELETE_IN_PROGRESS" { 
                Write-Host "$profile returned with a status of DELETE_IN_PROGRESS" -ForegroundColor Yellow
            }
            "DELETE_FAILED" { 
                Write-Host "$profile returned with a status of DELETE_FAILED" -ForegroundColor Red
            }
            "ROLLBACK_COMPLETE" { 
                Write-Host "$profile returned with a status of ROLLBACK_COMPLETE" -ForegroundColor Red
            }
            "ROLLBACK_IN_PROGRESS" { 
                Write-Host "$profile returned with a status of ROLLBACK_IN_PROGRESS" -ForegroundColor Yellow
            }
            "ROLLBACK_FAILED" { 
                Write-Host "$profile returned with a status of ROLLBACK_FAILED" -ForegroundColor Red
            }
            default { 
                Write-Host "$profile returned with a status of $($stack.StackStatus)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        if ($_.Exception.Message -like "*does not exist*") {
            Write-Host "${profile}: Stack does not exist" -ForegroundColor Yellow
            return
        }
        Write-Error "Error checking stack status: $_"
        throw $_
    }
}
