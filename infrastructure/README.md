# IaC Configuration

If you are using this within a corporate network, you can create a `.corporateEnvfile` for this processing to source and set the following variables:

|Variable|Purpose|Example|
|---|---|---|
|CL_IAC_AUTH_URL|The URL for authenticating with your infrastructure provider (e.g., OpenStack)|-|
|CL_IAC_PROJECT_ID|The ID of the project within the infrastructure provider|-|
|CL_IAC_PROJECT_DOMAIN_ID|The ID of your domain within the infrastructure provider|-|
|CL_IAC_PROJECT_NAME|The name of your project within your infrastructure provider|-|
|CL_IAC_USER_DOMAIN_NAME|The domain of your IaC user|-|
|CL_IAC_USERNAME|The username of your IaC user|-|
|CA_CHAIN_URL|The URL containing the Certificate Authority trust chains|-|
|HTTP_PROXY|Relevant settings for your HTTP proxy|-|
|http_proxy|Relevant settings for your HTTP proxy|-|
|HTTPS_PROXY|Relevant settings for your HTTPS proxy|-|
|https_proxy|Relevant settings for your HTTPS proxy|-|
|ALL_PROXY|Relevant settings for your ALL proxy|-|
|no_proxy|Relevant settings for excluding from filtering through a proxy|127.0.0.1,localhost|

**NOTE:** You should also pull from the CA source and emit the archive as `$CA_CHAIN_ARCHIVE`
```sh
curl $CA_CHAIN_URL --output $CA_CHAIN_ARCHIVE
```
