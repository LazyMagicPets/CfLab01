---
layout: default
title: CF Lab 01
---

# CF Lab 01

You will have received an invite to join the lab organization using your email address as your AWS SSO login name. After logging in, you will have access to an account you will use during this lab. During the lab, you will use the AWS Browser Console to create and edit AWS resources for a variety of services. Your login provides you with the permissions necessary for each of these services.

Each account has:
- ParticipantId between 01 and 99.
- a name of the form `CFLab{ParticipantId}` example `CFLab01`
- a domain name of the form `CFLab{ParticipantId}.click` example `CFLab01.click`

This lab as the following sections:
- [CF Lab 01](#cf-lab-01)
  - [Section 1 - Simple CloudFront Function](#section-1---simple-cloudfront-function)
  - [Section 2 - Review CloudFront Distribution](#section-2---review-cloudfront-distribution)
    - [General Tab](#general-tab)
    - [Security Tab](#security-tab)
    - [Origins Tab](#origins-tab)
      - [TenancyAssetOrigin](#tenancyassetorigin)
      - [ApiOrigin](#apiorigin)
    - [Behaviors Tab](#behaviors-tab)
      - [/Config Behavior](#config-behavior)
      - [`/*Api/*` Behavior](#api-behavior)
      - [Default(\*) Behavior](#default-behavior)
  - [Section 3 - Create a Behavior to call our Function](#section-3---create-a-behavior-to-call-our-function)
  - [Section 4 - Test calling MyFunction](#section-4---test-calling-myfunction)
  - [Section 5 - Examine CloudWatch log activity](#section-5---examine-cloudwatch-log-activity)
  - [Section 6 - Add an entry to the KeyValueStore](#section-6---add-an-entry-to-the-keyvaluestore)
  - [Section 7 - Associate KeyValueStore with MyFunction](#section-7---associate-keyvaluestore-with-myfunction)
  - [Section 8 - Lab Review Simple CloudFront Function](#section-8---lab-review-simple-cloudfront-function)
- [Section 9 - DeepDive into lzm---Request Function](#section-9---deepdive-into-lzm---request-function)


## Section 1 - Simple CloudFront Function  
In this exercise we will create a simple CloudFront function. 

1. Navigate to `CloudFront` Service
2. Click `Functions` in the menu
3. Under the `Functions tab`, click the `Create function` button
4. Enter these values:
    - Name: MyFunction
    - Description: Play
    - Runtime: cloudfront-js-2.0
8. Click the `Create function` button on bottom right of page
9. Scroll down to the `Build tab` 
10. Drop the following code into the Development editor
```javascript
function handler(event) {
    // NOTE: This example function is for a viewer request event trigger. 
    // Choose viewer request for event trigger when you associate this function with a distribution. 
    var response = {
        statusCode: 200,
        statusDescription: 'OK',
        headers: {
            'myfunction': { value: 'play' }
        },
        body: `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MagicPets MyFunction page</title>
</head>
<body>
    <h1>MyFunction page</h1>
</body>
</html>`
    };
    console.log('MagicPets MyFunction says hello! ');
    return response;
}
```
1.  Click on the `Save changes` button
2.  Click on the `Test tab`
3.  Click on the `Test function` button
4.  Scroll down to view the `Execution` result. You should see this output:

Output
```json
{
  "response": {
    "statusCode": 200,
    "statusDescription": "OK",
    "headers": {
      "myfunction": {
        "value": "play"
      }
    },
    "cookies": {},
    "body": {
      "encoding": "text",
      "data": "\r\n<!DOCTYPE html>\r\n<html lang=\"en\">\r\n<head>\r\n    <meta charset=\"UTF-8\">\r\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\r\n    <title>MagicPets MyFunction page</title>\r\n</head>\r\n<body>\r\n    <h1>MyFunction page</h1>\r\n</body>\r\n</html>"
    }
  }
}
```
Execution logs
```
MagicPets PlayFunction says hello! 
```
5. Click on the `Publish` tab
6. Click on the `Publish function` tab

## Section 2 - Review CloudFront Distribution
1. Click on `Distributions` in the menu
2. Click on the Distribution in the Distributions list
### General Tab
1. Note the following items in the `General tab`
   - Alternate domain names: *.cflab99.click, cflab99.click
   - Default root object: index.html
### Security Tab
1. Click on the Security tab. Note that we have not enable WAF.
### Origins Tab
1. Click on the `Origins tab`.
2. Note the two origins we have defined:
   - ApiOrigin
   - TenancyAssetOrigin
#### TenancyAssetOrigin
1. Click the `radio button` next to the `TenancyAssetsOrigin`
2. Click the `Edit` button
3.  Note the following items:
    - Origin domain: lzm-mp-assets-{suffix}.s3.us-west-2.amazonaws.com
    - Origin path: empty.
    - Name: TenancyAssetsOrigin
    - Origin access: Origin access control settings
    - Origin access control: lzm-mp--oac
    - Enable Origin Shield: No
    - Additional settings
      - Connection attempts: 3
      - Connection timeout: 10
      - Response timeout: 30 (only used for custom and VPC origins)
      - Keep-alive timeout: 5 (only used for custom and VPC origins)
4. Click on the `Cancel` button

#### ApiOrigin
1. Click the `radio button` next to the ApiOrigin
2. Click the `Edit` button
   - Note: this is a "custom" origin
   - Origin domain: cfalab99.click.
   - Protocol: HTTPS only
   - Minimum Origin SSL protocol: TLSv1.2
   - Origin path: /dev (this is usually the ApiGateway Stage)
   - Name: ApiOrigin
   - Add custom header: none
   - Enable Origin Shield: No
    - Additional settings
      - Connection attempts: 3
      - Connection timeout: 10
      - Response timeout: 30 (Active here because this is a custom origin)
      - Keep-alive timeout: 5 (Active here because this is a custom origin)
3.  Click the `Cancel` button

### Behaviors Tab
1. Click the `Behaviors tab`
2. Note the behaviors we have defined
    - `/config`
    - `/*Api/*`
    - `Default(*)`
#### /Config Behavior
1. Click the `radio button` next to the `/config` behavior
2. Click the `Edit` button 
3. Note the following properties:
   - Path pattern: `/config`
   - Origin and origin groups: TenancyAssetsOrigin
   - Compress objects automatically: no
   - Viewer protocol policy: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
   - Restrict viewer access: No
   - Cache policy and origin request policy: selected
     - Cache policy: lzm-CachingOptimizedDev (note this one is for the Dev environment)
     - Origin request policy: AllViewerExceptHostHeader
   - Response headers policy: lzm-mp--ResponseHeadersPolicy
   - Additional settings
     - Smooth streaming: no
     - Field-level encryption: no
     - Enable real-time logs: no
   - Function Associations
     - Viewer request: CloudFunctions, lzm--authconfig
     - Viewer response: none
     - Origin request: none
     - Origin response: none
4. Click the `Cancel` button

#### `/*Api/*` Behavior
1. Click the `radio button` next to the `/*Api/*` behavior
2. Click the `Edit` button
3. Note the following properties:
   - Path pattern: `/*Api/*`
   - Origin and origin groups: ApiOrigin
   - Compress objects automatically: No
   - Viewer protocol policy: HTTPS only
   - Viewer protocol policy: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
   - Restrict viewer access: No
   - Cache policy and origin request policy: selected
     - Cache policy: Caching Disabled
     - Origin request policy: AllViewerExceptHostHeader
   - Response headers policy: lzm-mp--ResponseHeadersPolicy
   - Additional settings
     - Smooth streaming: no
     - Field-level encryption: no
     - Enable real-time logs: no
   - Function Associations
     - Viewer request: CloudFunctions, lzm--request
     - Viewer response: none
     - Origin request: none
     - Origin response: none
  4. Click the `Cancel` button

####  Default(*) Behavior 
   - Path pattern: `Default(*)`
   - Origin and origin groups: TenancyAssetOrigin
   - Compress objects automatically: No
   - Viewer protocol policy: HTTPS only
   - Viewer protocol policy: GET, HEAD
   - Restrict viewer access: No
   - Cache policy and origin request policy: selected
     - Cache policy: lzm-CacheByHeaderDevPolicy
     - Origin request policy: AllViewerExceptHostHeader
   - Response headers policy: lzm-mp--ResponseHeadersPolicy
   - Additional settings
     - Smooth streaming: no
     - Field-level encryption: no
     - Enable real-time logs: no
   - Function Associations
     - Viewer request: CloudFunctions, lzm--request
     - Viewer response: none
     - Origin request: none
     - Origin response: none
  4. Click the `Cancel` button   
  
## Section 3 - Create a Behavior to call our Function
1. Click on `Create behavior` button
2. Enter these values:
   - Path pattern: `/myfunction`
   - Origin and origin groups: TenancyAssetOrigin
   - Compress objects automatically: No
   - Viewer protocol policy: HTTPS only
   - Viewer protocol policy: GET, HEAD
   - Restrict viewer access: No
   - Cache policy and origin request policy: selected
     - Cache policy: lzm-CacheByHeaderDevPolicy
     - Origin request policy: AllViewerExceptHostHeader
   - Response headers policy: lzm-mp--ResponseHeadersPolicy
   - Additional settings
     - Smooth streaming: no
     - Field-level encryption: no
     - Enable real-time logs: no
   - Function Associations
     - Viewer request: CloudFunctions, MyFunction
     - Viewer response: none
     - Origin request: none
     - Origin response: none
3. Click the `Create behavior` button  

## Section 4 - Test calling MyFunction
1. On a new browser tab, enter https://cflab99.click/myfunction (replacing cflab99.click with your domain)

## Section 5 - Examine CloudWatch log activity
1. Back in the AWS Dashboard, navigate to the CloudWatch service
2. Make sure you have the N.Virgina (us-west-2) region selected
3. Click on `Log groups` in the menu
4. Click on the `aws/cloudfront/function/MyFunction` log group
5. Click on the newest log stream
6. You should see entries similar to this:

|TimeStamp|Message|
|---|---|
|2025-04-15T07:15:08.945-07:00|mDUvoFjljgQbOq8qGvvhZwHO9ozqlHZERSONLThbGD7EskWPRIljNw== START |DistributionID: E2JJB7B8D3WB4E
|2025-04-15T07:15:08.945-07:00|mDUvoFjljgQbOq8qGvvhZwHO9ozqlHZERSONLThbGD7EskWPRIljNw== MagicPets MyFunction says hello!|
|2025-04-15T07:15:08.945-07:00|mDUvoFjljgQbOq8qGvvhZwHO9ozqlHZERSONLThbGD7EskWPRIljNw== END|

## Section 6 - Add an entry to the KeyValueStore
1. Navigate to the CloudFront service
2. Click on the `Functions` menu item
3. Click on the `KeyValueStores` tab
4. Click the `lzm---kvs` KeyValueStore item
5. In the Key value pairs section, click the `Edit` button
6. Click the `Add pair` button
7. Key: MyFunction
8. Value: Yada
9. Click on the `Save changes` button
10. Click `done` in the KeyValueStores update dialog

## Section 7 - Associate KeyValueStore with MyFunction
1. Click `Functions` in the menu
2. Click on `MyFunction` function
3. Click on the `Associate existing KeyValueStore` button
4. Select `lzm---kvs` as the KeyValueStore
5. Click the `Assoicate KeyValueStore` button
6. Copy the following code in the function editor:
```javascript
import cf from 'cloudfront';
const kvsHandle = cf.kvs();
async function handler(event) {
    // NOTE: This example function is for a viewer request event trigger. 
    // Choose viewer request for event trigger when you associate this function with a distribution. 
    // We also retrieve and use a value from the KeyValueStore
    let value = "Not found";
    try {
        value = await kvsHandle.get('MyFunction');
    } catch (err) {
        console.log(`Kvs key lookup failed for MyFunction: ${err}`);
    }    
    
    let htmlbody = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MagicPets MyFunction page</title>
</head>
<body>
    <h1>MyFunction page</h1>
    <h2>${value}</h2>
</body>
</html>`;

    htmlbody = htmlbody.replace('${value}',value);

    var response = {
        statusCode: 200,
        statusDescription: 'OK',
        headers: {
            'myfunction': { value: value }
        },
        body: htmlbody
    };
    console.log('MagicPets MyFunction says hello! ');
    return response;
}
```
7. Click on the `Save changes` button
8. Click on the `Test tab`
9. Click on the `Test function` button
10. Scroll down to view the `Execution` result. You should see this output:

Output
```json
{
  "response": {
    "statusCode": 200,
    "statusDescription": "OK",
    "headers": {
      "myfunction": {
        "value": "Yada"
      }
    },
    "cookies": {},
    "body": {
      "encoding": "text",
      "data": "\r\n<!DOCTYPE html>\r\n<html lang=\"en\">\r\n<head>\r\n    <meta charset=\"UTF-8\">\r\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\r\n    <title>MagicPets MyFunction page</title>\r\n</head>\r\n<body>\r\n    <h1>MyFunction page</h1>\r\n    <h2>Yada</h2>\r\n</body>\r\n</html>"
    }
  }
}
```
Execution logs
```
MagicPets PlayFunction says hello! 
```
5. Click on the `Publish` tab
6. Click on the `Publish function` tab
7. In a different browser tab, enter: https://cflab99.click/myfunction 
8. You should see content like this:
```
MyFunction page
Yada
```
## Section 8 - Lab Review Simple CloudFront Function
So far, we have:
- Navigated to the CloudFront service
- Reviewed an existing distribution
  - Noted these distribution general values
    - Alternate domain names (*.cflab99.click, cflab99.click)
    - Default root object: indexhtml
  - Reviewed the distribution's Origins
    - ApiOrigin
    - TenancyAssetsOrigin
  - Reviewed the distribution's Behaviors
    - `/config`
    - `/*Api/*`
    - `Default(*)`
- Explored a simple CloudFront Function
  - Created MyFunction
  - Tested MyFunction
  - Published MyFunction
- Added a Behavior `/myfunction`
  - Associated the CloudFront Function MyFunction to the Viewer Request event
- Used a browser to access `https://cflab99.click/myfunction`
- Navigated to the CloudWatch service 
  - Rviewed the log group output for /aws/cloudfront/function/MyFunction
- Navigated to the CloudFront service
- Added an entry to the KeyValueStore: MyFuction, Yada
- Associated the MyFunction function with the KeyValueStore and updated the function to use the KVS
- Tested the function
- Published the function
- Used a browser to access `https://cflab99.click/myfunction`

# Section 9 - DeepDive into lzm---Request Function
The `lzm---Request` Function is a general purpose function that handles a variety of use cases:
- Handles preflight requests for dev environment
- Reads the KVS JSON value for the current `host` ex: uptown.cflab99.click 
- Builds an array of Behaviors (mappings) from JSON data
- Uses the behavior path pattern to select behavior
- If a redirect is found we return a status 301 with a location header
- Process the behavior based on assetType: `api`, `assets`, `webapp`
- Resolve replacement targets: `{sts}`, `{ts}`, `{ss}`
- Handle Single Page App (SPA) navigation issues (requires sub-pages names to end in `Page`)
- Remove the path prefix if necessary
- Create a cacheKeyValue based on the asset requested and add it as a header
- Handle default routine. e.g. `/`
- Create the dynamic request origin
  - assetname
  - originPath
- Returns modified Request

Here's the `lzm---request` function code:
```javascript
import cf from 'cloudfront';
const kvsARN = "arn:aws:cloudfront::471303021085:key-value-store/9c1e5695-de85-4d94-80a2-55ece819e69b";
const kvs = cf.kvs(); 

async function handler(event) {
    try {
        const request = event.request;
        const headers = request.headers;
        const origin = headers.origin && headers.origin.value;
        const originalUri = request.uri;
        const originalDomain = headers.host.value;
        if(!request.uri) request.uri = '/';

        // Helper function for error responses
        const err = (code, msg) => ({statusCode: code, statusDescription: code === 404 ? 'Not Found' : 'Error', body: msg});

        // Get config
        let config = await GetConfig(headers.host.value);
        const configJson = JSON.stringify(config);  

        // Handle preflight requests
        if (config.env === 'dev' && request.method === 'OPTIONS' && origin && 
            origin.startsWith('http://localhost:') && headers['access-control-request-method']) {
            return {
                statusCode: 204,
                statusDescription: 'No Content',
                headers: {
                    'access-control-allow-origin': {value: origin},
                    'access-control-allow-methods': {value: 'GET, HEAD, POST, PUT, DELETE, CONNECT, OPTIONS, TRACE, PATCH'},
                    'access-control-allow-headers': {value: 'Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token'},
                    'access-control-max-age': {value: '86400'},
                    'cache-control': {value: 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0'}
                }
            };
        }

        // Set up keys
        const systemKey = config.systemKey;
        const tenantKey = config.tenantKey || '';
        const subtenantKey = config.subtenantKey || '';

        // Find matching behavior
        let behavior = null;
        let redirectPath = null;
        if(config.behaviors) {
            // Create flattened behavior reference array with prefixes
            const behaviorsRef = [];
            config.behaviors.forEach((b, i) => {
                const paths = b[0].split(',');
                paths.forEach((prefix,p) => {
                    const redirectPath = (p !== 0 ? paths[0] : null);
                    behaviorsRef.push([prefix, i, redirectPath]);
                });
            });

            // Sort by path length (longest first) and find first match
            behaviorsRef.sort((a, b) => b[0].length - a[0].length);

            for(let i = 0; i < behaviorsRef.length; i++) {
                if (request.uri.startsWith(behaviorsRef[i][0])) {
                    redirectPath = behaviorsRef[i][2];
                    behavior = config.behaviors[behaviorsRef[i][1]];
                    break;                
                }            
            }
        }   

        if(redirectPath) {
            return {
                statusCode: 302,
                statusDescription: 'Found',
                headers: {location: {value: redirectPath}}
            };
        }

        if(!behavior) return err(404, 'No path match');

        // Process behavior
        const assetType = behavior[1];
        const awsSuffix = '.amazonaws.com';
        let originPath = "";
        let removePrefix = false;
        let addCacheHeader = false;
        let assetName = "";

        switch(assetType) {
            case "api":
                assetName = behavior[2] + '.execute-api.' + behavior[3] + awsSuffix;
                removePrefix = true;
                originPath = "/" + config.env;
                headers['lz-config'] = {value: configJson};
                headers['lz-tenantid'] = {value: headers.host.value}; 
                const authheader = headers['authorization'] && headers['authorization'].value;
                if(authheader && authheader.startsWith('AWS4-HMAC-SHA256 Credential=')) {
                    headers['lz-config-authorization'] = {value: authheader};
                }
                headers['lz-aws-kvsarn'] = {value: kvsARN};
                break;
            case "assets":
                const behaviorLevel = behavior[4];
                const assetTenantKey = behaviorLevel > 0 ? tenantKey : '';
                const assetSubtenantKey = behaviorLevel > 1 ? subtenantKey : '';
                assetName = systemKey + '-' + assetTenantKey + '-' + assetSubtenantKey + '-' + assetType + '-' + behavior[2] + '.s3.' + behavior[3] + awsSuffix;
                removePrefix = true;
                addCacheHeader = true;
                break;
            case "webapp":
                const webLevel = behavior[4];
                const webTenantKey = webLevel > 0 ? tenantKey : '';
                const webSubtenantKey = webLevel > 1 ? subtenantKey : '';
                assetName = systemKey + '-' + webTenantKey + '-' + webSubtenantKey + '-' + assetType + '-' + behavior[2] + '-' + behavior[3] + '.s3.' + behavior[4] + awsSuffix;
                removePrefix = true;
                addCacheHeader = true;
                originPath = "/wwwroot";
                break;
        }

        // Perform replacements in assetName
        assetName = assetName
            .replaceAll('{sts}', config.sts)
            .replaceAll('{ts}', config.ts)
            .replaceAll('{ss}', config.ss);

        if (assetName.includes('{')) return err(404, 'Bad Config behavior entry');

        // Handle webapp Page URLs
        if (assetType == 'webapp' && request.uri.endsWith("Page")) {
            request.uri = request.uri.substring(0, request.uri.lastIndexOf('/'));
        }

        if(removePrefix) {
            const secondSlash = request.uri.indexOf('/', 1); 
            request.uri = secondSlash > 0 ? request.uri.slice(secondSlash) : '/';
        }

        const cacheKeyValue = assetName + '-' + originPath + '-' + request.uri;
        if(addCacheHeader) {
            headers['x-custom-cache-key'] = {value: cacheKeyValue};
        }


        if(request.uri === '/') {
            headers['referrer'] = {value: originalDomain + '/sets'};
        }


        console.log("request: " + originalDomain + originalUri + ", redirect: " + assetName + originPath + request.uri + " cachekey: " + cacheKeyValue);

        cf.updateRequestOrigin({
            "domainName": assetName,
            "originPath": originPath
        });

        return request;
    } catch (e) {
        console.log('Unhandled error: ' + (e.message || e));
        return {statusCode: 500, statusDescription: 'Error', body: 'Internal Server Error'};
    }

    async function GetConfig(host) {
        try {
            const configJson = await kvs.get(host);
            if (!configJson) throw Error("Missing Config");
            let config = JSON.parse(configJson);
            if (!config || (!config.behaviors && !config.redirecthost)) throw new Error("Bad Config");
            return config;
        } catch (e) {
            console.log(e.message);
            throw e;
        }        
    }
}

```