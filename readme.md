---
layout: default
title: CF Lab 01
---

# CF Lab 01

You will have received an invite to join the lab organization using your email address as your AWS SSO login name. After logging in, you will have access to an account you will use during this lab. During the lab, you will use the AWS Browser Console to create and edit AWS resources for a variety of services. Your login provides you with the permissions necessary for each of these services.

Each account has a name of the form ```CFLab99`` where the number is between 01 and 99.

## 1. Direct Mapping Exercise  
In this exercise we will modify an existing CloudFront distribution to demonstrate Direct Mapping.

1. Navigate to the CloudFront Service
2. Select the existing CloudFront distribution - there will be only one
3. Select the Behaviors tab
4. Click the Create behavior button
5. Path Pattern: /store
6. Origin: lzm---webapp-myapp-{suffix}.s3.us-west-2.amazonaws.com
8. Click Create behavior button at bottom of page
9. Move behavior to top of Behaviors list
10. Click the Save button
11. Click the create behavior button
12. Path Pattern: /tenancy
13. Origin: lzm-mp--assets-{sufix}.s3.us-west-2.amazonaws.com
14. Click the create behavior button
15.  Move behavior to top of Behaviors list
16. Click the Save button






