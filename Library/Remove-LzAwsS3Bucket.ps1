<#
.SYNOPSIS
    Removes an AWS S3 bucket and its contents
.DESCRIPTION
    Removes an AWS S3 bucket and all its contents. This is a destructive operation.
    The function will first empty the bucket and then delete it.
.PARAMETER BucketName
    The name of the S3 bucket to remove
.PARAMETER Region
    The AWS region where the bucket is located
.PARAMETER Account
    The AWS account ID where the bucket is located
.PARAMETER ProfileName
    The AWS profile name to use for authentication
.EXAMPLE
    Remove-LzAwsS3Bucket -BucketName "my-bucket" -Region "us-west-2" -Account "123456789012" -ProfileName "my-profile"
    Removes the specified S3 bucket and all its contents
.NOTES
    This is a destructive operation. All data in the bucket will be permanently deleted.
    The function requires appropriate IAM permissions to delete buckets and their contents.
.OUTPUTS
    None
#>
function Remove-LzAwsS3Bucket {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$BucketName,
        
        [Parameter(Mandatory=$true)]
        [string]$Region,
        
        [Parameter(Mandatory=$true)]
        [string]$Account,
        
        [Parameter(Mandatory=$true)]
        [string]$ProfileName
    )

    try {
        # First, check if the bucket exists
        Write-Host "Checking if bucket exists: $BucketName"
        try {
            aws s3api head-bucket --bucket $BucketName --region $Region --profile $ProfileName
        }
        catch {
            if ($_.Exception.Message -match "404") {
                Write-Host "Bucket $BucketName does not exist, skipping deletion"
                return
            }
            throw
        }

        # If we get here, the bucket exists, so proceed with emptying it
        Write-Host "Emptying bucket: $BucketName"
        try {
            $objects = aws s3api list-objects-v2 --bucket $BucketName --region $Region --profile $ProfileName | ConvertFrom-Json
            if ($objects.Contents) {
                # Create a temporary file for the delete objects JSON
                $tempFile = [System.IO.Path]::GetTempFileName()
                try {
                    $deleteObjects = @()
                    foreach ($object in $objects.Contents) {
                        $deleteObjects += @{Key = $object.Key}
                    }
                    $deleteObjectsJson = @{
                        Objects = $deleteObjects
                        Quiet = $true
                    } | ConvertTo-Json -Compress
                    
                    # Write the JSON to the temp file
                    [System.IO.File]::WriteAllText($tempFile, $deleteObjectsJson)
                    
                    # Use the temp file with the delete-objects command
                    aws s3api delete-objects --bucket $BucketName --delete "file://$tempFile" --region $Region --profile $ProfileName
                }
                finally {
                    # Clean up the temp file
                    if (Test-Path $tempFile) {
                        Remove-Item $tempFile
                    }
                }
            }
        }
        catch {
            Write-Host "Error emptying bucket $BucketName : $_"
            throw
        }

        # Then delete the bucket
        Write-Host "Deleting bucket: $BucketName"
        try {
            aws s3api delete-bucket --bucket $BucketName --region $Region --profile $ProfileName
            Write-Host "Successfully removed bucket: $BucketName"
        }
        catch {
            Write-Host "Error deleting bucket $BucketName : $_"
            throw
        }
    }
    catch {
        Write-Host "Error removing bucket $BucketName : $_"
        throw
    }
} 