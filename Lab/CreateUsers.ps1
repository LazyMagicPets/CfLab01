<#
.SYNOPSIS
    Creates users in AWS SSO and assigns them to accounts with a permission set
.DESCRIPTION
    Creates users in AWS SSO with sequential usernames and assigns each to a corresponding
    AWS account with the CFLabPermissions permission set. Skips emails that are already
    associated with users and finds the next available user number.
    
    Note: If users are deleted from AWS SSO, their emails can be reused in subsequent runs
    of this script. The script only checks for currently existing users, not historical ones.
.PARAMETER EmailFile
    Path to a text file containing one email address per line
.EXAMPLE
    .\CreateUsers.ps1 -EmailFile "emails.txt"
.NOTES
    Requires AWS CLI and appropriate permissions to create SSO users and assignments
#>

function New-CfLabUsers {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EmailFile
    )

    # Prompt for AWS SSO profile
    $ProfileName = Read-Host "Enter AWS SSO profile name"
    if (-not $ProfileName) {
        Write-Error "Profile name is required"
        exit 1
    }

    # Read emails from file
    if (-not (Test-Path $EmailFile)) {
        Write-Error "Email file not found: $EmailFile"
        exit 1
    }

    $EmailList = Get-Content $EmailFile | Where-Object { $_ -match '^\S+@\S+\.\S+$' }
    if (-not $EmailList) {
        Write-Error "No valid email addresses found in $EmailFile"
        exit 1
    }

    Write-Host "Found $($EmailList.Count) valid email addresses in $EmailFile"

    # Get AWS SSO instance ARN and identity store ID
    Write-Host "Getting AWS SSO instance information..." -ForegroundColor Yellow
    $ssoInstances = aws sso-admin list-instances --profile $ProfileName --output json | ConvertFrom-Json
    if (-not $ssoInstances -or -not $ssoInstances.Instances) {
        Write-Error "Failed to get SSO instances. Please ensure you have the correct permissions and the SSO instance exists."
        exit 1
    }

    $ssoInstanceArn = $ssoInstances.Instances[0].InstanceArn
    $identityStoreId = $ssoInstances.Instances[0].IdentityStoreId

    Write-Host "Found SSO Instance ARN: $ssoInstanceArn" -ForegroundColor Green
    Write-Host "Found Identity Store ID: $identityStoreId" -ForegroundColor Green

    # Get permission set ARN
    Write-Host "Getting permission set ARN..." -ForegroundColor Yellow
    $permissionSets = aws sso-admin list-permission-sets --instance-arn $ssoInstanceArn --profile $ProfileName --output json | ConvertFrom-Json
    if (-not $permissionSets) {
        Write-Error "Failed to list permission sets. Please ensure you have the correct permissions."
        exit 1
    }

    # Get details of each permission set to find the correct one
    $permissionSetDetails = @()
    foreach ($arn in $permissionSets.PermissionSets) {
        $details = aws sso-admin describe-permission-set --instance-arn $ssoInstanceArn --permission-set-arn $arn --profile $ProfileName --output json | ConvertFrom-Json
        $permissionSetDetails += $details
    }

    # Look for permission set with name containing "CFLab"
    $permissionSetArn = $permissionSetDetails | Where-Object { $_.PermissionSet.Name -match 'CFLab' } | Select-Object -ExpandProperty PermissionSet -First 1 | Select-Object -ExpandProperty PermissionSetArn

    if (-not $permissionSetArn) {
        Write-Error "No permission set containing 'CFLab' found. Available permission sets:"
        $permissionSetDetails | ForEach-Object { Write-Host "- $($_.PermissionSet.Name)" }
        exit 1
    }

    Write-Host "Found permission set: $($permissionSetDetails | Where-Object { $_.PermissionSet.PermissionSetArn -eq $permissionSetArn } | Select-Object -ExpandProperty PermissionSet -First 1 | Select-Object -ExpandProperty Name)" -ForegroundColor Green

    # Get existing users to check for duplicates
    $existingUsers = aws identitystore list-users --identity-store-id $identityStoreId --output json --profile $ProfileName | ConvertFrom-Json
    $existingEmails = @{}
    $existingUserNumbers = @()

    foreach ($user in $existingUsers.Users) {
        $email = ($user.Emails | Where-Object { $_.Primary -eq $true }).Value
        if ($email) {
            $existingEmails[$email] = $true
            # Extract number from username if it matches our pattern
            if ($user.UserName -match 'cflabuser-(\d{2})') {
                $existingUserNumbers += [int]$Matches[1]
            }
        }
    }

    # Find the next available user number
    $nextUserNumber = 1
    if ($existingUserNumbers.Count -gt 0) {
        $nextUserNumber = ($existingUserNumbers | Measure-Object -Maximum).Maximum + 1
    }

    # Create users and assign them to accounts
    $createdCount = 0
    $skippedCount = 0
    foreach ($email in $EmailList) {
        # Skip if email already exists
        if ($existingEmails.ContainsKey($email)) {
            Write-Host "Skipping $email - already associated with a user"
            $skippedCount++
            continue
        }

        # Check if we've reached the maximum number of users
        if ($nextUserNumber -gt 20) {
            Write-Host "Maximum number of users (20) reached. Skipping remaining emails."
            break
        }

        try {
            # Calculate the user number based on skipped emails
            $userNumber = ($nextUserNumber + $skippedCount).ToString("00")
            $username = "cflab$userNumber"
            $displayName = $username
            $accountId = aws organizations list-accounts --query "Accounts[?Name=='CFlab-$userNumber'].Id" --output text --profile $ProfileName

            if (-not $accountId) {
                Write-Error "Failed to get account ID for CFlab-$userNumber"
                continue
            }

            # Create user in AWS SSO
            Write-Host "Creating user $username..."
            $user = aws identitystore create-user `
                --identity-store-id $identityStoreId `
                --user-name $username `
                --display-name $displayName `
                --name "GivenName=$userNumber,FamilyName=cflab" `
                --emails "Value=$email,Type=Work,Primary=true" `
                --output json `
                --profile $ProfileName

            if (-not $user) {
                Write-Error "Failed to create user $username"
                continue
            }

            $userId = ($user | ConvertFrom-Json).UserId
            Write-Host "Successfully created user $username" -ForegroundColor Green

            # Assign user to account with permission set
            Write-Host "Assigning user $username to account CFlab-$userNumber..."
            $assignment = aws sso-admin create-account-assignment `
                --instance-arn $ssoInstanceArn `
                --target-id $accountId `
                --target-type AWS_ACCOUNT `
                --permission-set-arn $permissionSetArn `
                --principal-type USER `
                --principal-id $userId `
                --profile $ProfileName

            if (-not $assignment) {
                Write-Error "Failed to assign user $username to account CFlab-$userNumber"
                continue
            }

            Write-Host "Successfully assigned user $username to account CFlab-$userNumber" -ForegroundColor Green
            Write-Host "User $email can set up their password by visiting: https://$identityStoreId.awsapps.com/start" -ForegroundColor Yellow
            $createdCount++
            $nextUserNumber++
        }
        catch {
            if ($_.Exception.Message -match "Duplicate UserName") {
                Write-Host "User $username already exists, skipping..." -ForegroundColor Yellow
                continue
            }
            Write-Error "Error processing user $email : $($_.Exception.Message)"
            continue
        }
    }

    Write-Host "User creation and assignment completed. Created $createdCount new users."
}

# Only run if script is called directly, not when imported
if ($MyInvocation.InvocationName -ne '.') {
    New-CfLabUsers @PSBoundParameters
}
