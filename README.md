# aws_sec

This repo creates and configures security resources on AWS. 
 need to be set locally:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
```

**1) Create a backend (S3 bucket and Dynamodb table) for the Terraform configuration.**

```
make create-backend
```

**2) Create resources:**
  
```
make apply
```

**3) Remove resources:**
  
```
make destroy
```

**4) Remove backend:**
  

**The following environment variables```
make destroy-backend
```

TODO:
* Secrets - https://blog.gruntwork.io/a-comprehensive-guide-to-managing-secrets-in-your-terraform-code-1d586955ace1
* Terratest
* Credentials
* Private VPC
* Cron for updates
* app logs to cloudwatch