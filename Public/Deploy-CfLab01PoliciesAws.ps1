# This script deploys as stack that creates the policies and functions used in CloudFront
    <#
    .SYNOPSIS
        Deploys IAM policies to AWS

    .DESCRIPTION
        Deploys or updates IAM policies in AWS, managing permissions
        and access controls across the infrastructure.

    .EXAMPLE
        Deploy-PoliciesAws 
        Deploys the specified IAM policies to AWS

    .OUTPUTS
        System.Object

    .NOTES
        Requires valid AWS credentials and appropriate permissions

    .LINK
        New-LzAwsCFPoliciesStack

    .COMPONENT
        LzAws
    #>      
function Deploy-CfLab01PoliciesAws {
    param(
        [Parameter(Mandatory=$true)]
        [string]$labprofile 
    )

    Deploy-Many -labprofile $labprofile -Function Deploy-PoliciesAws
}
