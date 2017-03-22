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
            "s3:CreateBucket"
          ],
          "Resource": [
            "*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "ec2:AttachInternetGateway",
            "ec2:CreateInternetGateway",
            "ec2:CreateTags",
            "ec2:CreateVpc",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInstances",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeKeyPairs",
            "ec2:DescribeSubnets",
            "ec2:DescribeTags",
            "ec2:DescribeVpcs",
            "ec2:ModifyVpcAttribute"
          ],
          "Resource": "*"
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

## Prepare Playbook

All commands below should be ran in the root of your `oauth2-s3-proxy` clone unless otherwise noted.

### Setup .vault_pass

Create a file named `.vault_pass`. Save the password you want to use for securing the Ansible files in the `.vault_pass` file. **This file should NOT be committed** and is excluded from versioning via `.gitignore`.

### Configure playbook

First, reset the encrypted config files to their templates:

```bash
make init
```

Next, find the access key ID and access secret located in the `credentials.csv` file you downloaded earlier.  Use these values to edit the encrypted file that configures the playbook's access to Amazon:
```bash
ansible-vault edit inventory/group_vars/production/aws.vault.yml
```
