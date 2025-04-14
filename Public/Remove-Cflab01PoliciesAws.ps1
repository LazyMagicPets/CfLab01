# This script deploys as stack that creates the policies and functions used in CloudFront
    <#
    .SYNOPSIS
        Removes IAM policies from AWS

    .DESCRIPTION
        Removes IAM policies from AWS

    .EXAMPLE
        Remove-Cflab01PoliciesAws 
        Removes the specified IAM policies from AWS

    .OUTPUTS
        System.Object

    .NOTES
        Requires valid AWS credentials and appropriate permissions

    .LINK
        New-LzAwsCFPoliciesStack

    .COMPONENT
        LzAws
    #>      
    function Remove-Cflab01PoliciesAws {
        param(
            [Parameter(Mandatory=$true)]
            [string]$labprofile 
        )
    
        Deploy-Many -labprofile $labprofile -Function Remove-PoliciesAws
    }
    