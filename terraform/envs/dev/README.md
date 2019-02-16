
**Instructions before giving the ```terraform init``` command for the first time.**

You must have created a S3 bucket and a DynamoDB table for the Terraform backend. Add those values to the dev.tf backend section configuration

Then create yourself AWS access and secret key. Go to AWS portal / IAM / YOUR-USER-ACCOUNT. You can find there "Security credentials" section => create the keys here. 

Then you should create an AWS profile to the configuration section in your ~/.aws/credentials. Add a section for your AWS account and copy-paste the keys there, e.g.:

```text
[my-aws-profile]
aws_access_key_id = YOUR-ACCESS-KEY
aws_secret_access_key = YOUR-SECRET-KEY
```

Then whenever you give terraform commands or use aws cli you should give the environment variable with the command, e.g.:

```bash
AWS_PROFILE=MY-PROFILE terraform init
```
