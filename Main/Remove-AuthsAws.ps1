<#
.SYNOPSIS
    Removes authentication configurations from AWS
.DESCRIPTION
    Removes authentication and authorization configurations
    from AWS, including Cognito User Pools, Identity Pools, and related resources.
.EXAMPLE
    Remove-AuthsAws
    Removes the authentication configurations defined in the system config
.NOTES
    Requires valid AWS credentials and appropriate permissions
.OUTPUTS
    System.Object
#>
function Remove-AuthsAws {
    [CmdletBinding()]
    param()
    Write-Host "Starting Authentication stack(s) removal..." -ForegroundColor Yellow
    try {
        Write-Host "Getting system configuration..." -ForegroundColor Yellow
        $null = Get-SystemConfig
        $ProfileName = $script:ProfileName
        $Region = $script:Region
        $Config = $script:Config

        if ($null -eq $Config) {
            $errorMessage = @"
Error: System configuration is missing Config section
Function: Remove-AuthsAws
Hints:
  - Check if Config section exists in systemconfig.yaml
  - Verify the configuration file structure
  - Ensure all required configuration sections are present
"@
            throw $errorMessage
        }

        $SystemKey = $Config.SystemKey

        # Verify deployment config exists
        if(-not (Test-Path -Path "./Generated/deploymentconfig.g.yaml" -PathType Leaf)) {
            $errorMessage = @"
Error: deploymentconfig.g.yaml does not exist
Function: Remove-AuthsAws
Hints:
  - Run the generation step before deployment
  - Check if the generation process completed successfully
  - Verify the deployment configuration was generated
"@
            throw $errorMessage
        }

        # Load deployment config
        try {
            $DeploymentConfig = Get-Content -Path "./Generated/deploymentconfig.g.yaml" | ConvertFrom-Yaml
        }
        catch {
            $errorMessage = @"
Error: Failed to load deployment configuration
Function: Remove-AuthsAws
Hints:
  - Check if deploymentconfig.g.yaml is valid YAML
  - Verify the file is not corrupted
  - Ensure the configuration format is correct
Error Details: $($_.Exception.Message)
"@
            throw $errorMessage
        }

        if ($null -eq $DeploymentConfig.Authentications) {
            $errorMessage = @"
Error: No authentication configurations found in deployment config
Function: Remove-AuthsAws
Hints:
  - Check if authentications are defined in the source config
  - Verify the generation process included authentications
  - Ensure the deployment config format is correct
"@
            throw $errorMessage
        }

        # Process each authenticator
        $Authenticators = $DeploymentConfig.Authentications
        foreach($Authenticator in $Authenticators) {
            $StackName = $Config.SystemKey + "---" + $Authenticator.Name
            Write-Host "Processing authenticator: $($Authenticator.Name)" -ForegroundColor Yellow

            # First check if stack exists
            Write-Host "Checking if stack exists..." -ForegroundColor Yellow
            $stackStatus = aws cloudformation describe-stacks `
                --stack-name $StackName `
                --region $Region `
                --profile $ProfileName 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                if ($stackStatus -match "Stack with id $StackName does not exist") {
                    Write-Host "Stack does not exist. Nothing to remove." -ForegroundColor Yellow
                    continue
                }
                throw "Failed to check stack status: $stackStatus"
            }

            # Initiate stack deletion
            Write-Host "Initiating stack deletion..." -ForegroundColor Yellow
            $result = aws cloudformation delete-stack `
                --stack-name $StackName `
                --region $Region `
                --profile $ProfileName 2>&1

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to initiate stack deletion: $result"
            }

            # Wait for deletion to complete
            Write-Host "Waiting for stack deletion to complete..." -ForegroundColor Yellow
            $maxAttempts = 3  # 30 seconds with 10 second intervals
            $attempt = 0
            
            while ($attempt -lt $maxAttempts) {
                $stackStatus = aws cloudformation describe-stacks `
                    --stack-name $StackName `
                    --region $Region `
                    --profile $ProfileName 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    if ($stackStatus -match "Stack with id $StackName does not exist") {
                        Write-Host "Stack deletion completed successfully." -ForegroundColor Green
                        break
                    }
                }
                
                Write-Host "Stack deletion in progress... (attempt $($attempt + 1))" -ForegroundColor Yellow
                Start-Sleep -Seconds 10
                $attempt++
            }

            if ($attempt -eq $maxAttempts) {
                throw "Stack deletion timed out after 30 seconds. Check CloudFormation console for details."
            }
        }

        # Delete the artifacts bucket
        Write-Host "Checking for artifacts bucket..." -ForegroundColor Yellow
        $ArtifactsBucket = $Config.SystemKey + "---artifacts-" + $Config.SystemSuffix
        $bucketExists = Test-S3BucketExists -BucketName $ArtifactsBucket
        
        if ($bucketExists) {
            Write-Host "Found artifacts bucket: $ArtifactsBucket" -ForegroundColor Yellow
            Write-Host "Deleting artifacts bucket..." -ForegroundColor Yellow
            try {
                aws s3 rb s3://$ArtifactsBucket --force --region $Region --profile $ProfileName
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to delete artifacts bucket"
                }
                Write-Host "Successfully deleted artifacts bucket" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to delete artifacts bucket: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "Artifacts bucket does not exist. Nothing to remove." -ForegroundColor Yellow
        }

        Write-Host "Successfully removed all authentication stacks" -ForegroundColor Green
    }
    catch {
        Write-Host ($_.Exception.Message) -ForegroundColor Red
        return $false
    }
    return $true
}
