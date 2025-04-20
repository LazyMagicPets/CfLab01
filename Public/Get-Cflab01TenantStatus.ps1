<#
.SYNOPSIS
    Gets the status of tenant CloudFormation stacks across AWS profiles
.DESCRIPTION
    Checks the status of the CloudFormation stack named 'lzm-mp--tenant' across specified AWS profiles.
    Can check a single profile or all configured profiles.
.PARAMETER labprofile
    The AWS profile to check. Can be a specific profile (e.g., "cflab-01") or "all" to check all profiles.
.EXAMPLE
    Get-Cflab01TenantStatus -labprofile "cflab-01"
    Checks the tenant stack status in the cflab-01 profile
.EXAMPLE
    Get-Cflab01TenantStatus -labprofile "all"
    Checks the tenant stack status across all configured profiles
#>
function Get-Cflab01TenantStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile
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

    # Filter out excluded accounts while maintaining order
    $activeProfiles = $orderedAccounts | Where-Object { -not $accountsConfig.Accounts[$_].exclude }

    if ($labprofile -eq "all") {
        foreach ($profile in $activeProfiles) {
            Write-Host "`nChecking $profile..." -ForegroundColor Cyan
            Set-SystemConfig -labprofile $profile
            $status = Get-TenantStatus
            
            if ($status) {
                # Display status with appropriate color
                switch ($status.Status) {
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
                        Write-Host "$profile returned with a status of $($status.Status)" -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "${profile}: Stack does not exist" -ForegroundColor Yellow
            }
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

        Write-Host "`nChecking $labprofile..." -ForegroundColor Cyan
        Set-SystemConfig -labprofile $labprofile
        $status = Get-TenantStatus
        
        if ($status) {
            # Display status with appropriate color
            switch ($status.Status) {
                "CREATE_COMPLETE" { 
                    Write-Host "$labprofile returned with a status of CREATE_COMPLETE" -ForegroundColor Green
                }
                "CREATE_IN_PROGRESS" { 
                    Write-Host "$labprofile returned with a status of CREATE_IN_PROGRESS" -ForegroundColor Yellow
                }
                "CREATE_FAILED" { 
                    Write-Host "$labprofile returned with a status of CREATE_FAILED" -ForegroundColor Red
                }
                "UPDATE_COMPLETE" { 
                    Write-Host "$labprofile returned with a status of UPDATE_COMPLETE" -ForegroundColor Green
                }
                "UPDATE_IN_PROGRESS" { 
                    Write-Host "$labprofile returned with a status of UPDATE_IN_PROGRESS" -ForegroundColor Yellow
                }
                "UPDATE_FAILED" { 
                    Write-Host "$labprofile returned with a status of UPDATE_FAILED" -ForegroundColor Red
                }
                "DELETE_COMPLETE" { 
                    Write-Host "$labprofile returned with a status of DELETE_COMPLETE" -ForegroundColor Green
                }
                "DELETE_IN_PROGRESS" { 
                    Write-Host "$labprofile returned with a status of DELETE_IN_PROGRESS" -ForegroundColor Yellow
                }
                "DELETE_FAILED" { 
                    Write-Host "$labprofile returned with a status of DELETE_FAILED" -ForegroundColor Red
                }
                "ROLLBACK_COMPLETE" { 
                    Write-Host "$labprofile returned with a status of ROLLBACK_COMPLETE" -ForegroundColor Red
                }
                "ROLLBACK_IN_PROGRESS" { 
                    Write-Host "$labprofile returned with a status of ROLLBACK_IN_PROGRESS" -ForegroundColor Yellow
                }
                "ROLLBACK_FAILED" { 
                    Write-Host "$labprofile returned with a status of ROLLBACK_FAILED" -ForegroundColor Red
                }
                default { 
                    Write-Host "$labprofile returned with a status of $($status.Status)" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "${labprofile}: Stack does not exist" -ForegroundColor Yellow
        }
    }
} 