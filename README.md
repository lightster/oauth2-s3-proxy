# oauth2-s3-proxy

This Ansible playbook sets up oauth2_proxy on AWS EC2 instances to proxy a web site hosted in S3 through SSO authentication.

## Prepare AWS

### Create an IAM Policy

1. [Go to IAM management](https://console.aws.amazon.com/iam/home) in the AWS Console
2. Select "Policies" in the left navigation
3. Select the "Create Policy" button near the top of the page
4. Select "Create Your Own Policy"
5. Name the policy `oauth2-s3-proxy-ansible`
6. For the policy document, paste the following policy:
    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "ec2:AllocateAddress",
            "ec2:AssociateAddress",
            "ec2:AssociateRouteTable",
            "ec2:AttachInternetGateway",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CreateInternetGateway",
            "ec2:CreateRoute",
            "ec2:CreateRouteTable",
            "ec2:CreateSecurityGroup",
            "ec2:CreateSubnet",
            "ec2:CreateTags",
            "ec2:CreateVpc",
            "ec2:DeleteKeyPair",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInstances",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeKeyPairs",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeTags",
            "ec2:DescribeVpcs",
            "ec2:ImportKeyPair",
            "ec2:ModifyVpcAttribute",
            "ec2:RunInstances",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
            "elasticloadbalancing:ConfigureHealthCheck",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateLoadBalancerListeners",
            "elasticloadbalancing:DeleteLoadBalancerListeners",
            "elasticloadbalancing:DescribeInstanceHealth",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeTags",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "s3:CreateBucket"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:*"
          ],
          "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME"
        }
      ]
    }
    ```

### Create an IAM User for Ansible

1. [Go to IAM management](https://console.aws.amazon.com/iam/home) in the AWS Console
2. Select "Users" in the left navigation
3. Select the "Add user" button near the top of the page
4. **User details**
    1. Enter `oauth2-s3-proxy-ansible` as the username
    2. For access type, select "Programmatic access"
    3. Select "Next: Permissions"
5. **Permissions**
    1. Select "Attach existing policies directly" icon near top of the page
    2. Search for and select `oauth2-s3-proxy-ansible`
    3. Select "Next: Review"
6. Select "Create User"
7. Download the credentials somewhere secure using the `Download .csv` button

### Find your SSL Certificate ARN in AWS Certificate Manager

1. [Go to Certificate Manager](https://console.aws.amazon.com/acm/home) in the AWS Console
2. Select the certificate that matches the domain you are using to serve your S3 site
3. Find and make note of the certificate ARN

## Prepare Google Project

### Create a Google API Project

1. [Go to Google API Manager](https://console.developers.google.com/apis/)
2. Next to the "Google APIs" logo, select "Project"
3. In the dropdown menu, select "Create project"
4. Enter a project name and create the project
5. Wait a few seconds for the project creation to complete

### Setup OAuth Consent Screen for Project

1. Select "Credentials" in left navigation
2. Select "OAuth consent screen" in top sub navigation
3. Choose an email address to use for the project contact
4. Enter a product name, such as "Hub"
5. Use the "Save" button to save the consent screen settings

### Setup Credentials for Project

1. Select "Credentials" in left navigation
2. Select the "Create Credentials" button in the middle of the page
3. Select "OAuth client ID"
4. Select "Web application" as application type
5. Enter a client ID name, such as "Hub"
6. Enter an authorized redirect URI, using your subdomain in place of hub.example.com: `https://hub.example.com/auth/callback`
7. Use the "Create" button to save the client ID settings
8. Make note of the client ID and client secret that Google provides upon client ID creation

## Prepare Playbook

All commands below should be ran in the root of your `oauth2-s3-proxy` clone unless otherwise noted.

### Setup .vault_pass

Create a file named `.vault_pass`. Save the password you want to use for securing the Ansible files in the `.vault_pass` file. **This file should NOT be committed** and is excluded from versioning via `.gitignore`.

### Configure playbook

First, reset the encrypted config files to their templates:

```bash
make init
```

Next, use the following command to edit the encrypted file that configures the secure values the playbook uses for setting up AWS:
```bash
ansible-vault edit inventory/group_vars/production/aws.vault.yml
```

In the `aws.vault.yml` file, be sure to:
 - Update the access key ID and access secret, which can be found in the `credentials.csv` file you downloaded earlier
 - Update the certificate ARN using the certificate ARN you made note of earlier

Then generate a cookie secret using the following command:
```bash
python -c 'import os,base64; print base64.b64encode(os.urandom(16))'
```

Make a short-term note of the cookie secret and use the following command to edit the secure values used for OAuth2 Proxy:
```bash
ansible-vault edit inventory/group_vars/production/oauth2_proxy.vault.yml
```

Your `oauth2_proxy.vault.yml` file will look something like:
```yaml
---

# The list of domains that should be granted access to the
# site after logging in with an email matching one of these
# domains
vault_auth_email_domain:
 - "example.com" # assumes G Suite email addresses like you@example.com

# Paths that should be accessible without authenticating. This
# is useful if you have assets you want to be useable on the
# login page
vault_auth_skip_auth_regex:
 - "/assets"

# Google OAuth client ID and secret
vault_auth_client_id: "a-google-provided-id.apps.googleusercontent.com"
vault_auth_client_secret: "a-google-provided-secret"

# The cookie secret used for keeping the cookie secure
vault_auth_cookie_secret: "the-python-generated-cookie-secret"

# The domain/subdomain to restrict the auth cookie to
vault_auth_cookie_domain: "hub.example.com"
```

## Run the Playbook

```bash
make vpc
```
