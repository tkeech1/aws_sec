# variables may not be used here
terraform {
  backend "s3" {
    bucket         = "tdk-terraform-state-awssec.io-dev"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-awssec-dev"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.11.0"
    }
  }
}

provider "aws" {
  region = var.region
}

/* Guard Duty */
/*module "guard_duty" {
  source      = "./modules/guardduty"
  environment = var.environment
}*/

/* Create an s3 bucket */
module "s3" {
  source             = "./modules/s3"
  source_bucket_name = var.s3_source_bucket_name
  environment        = var.environment
  sse_algorithm      = var.sse_algorithm
}

/* Create an ec2 server with ssh access */
module "ec2_webserver" {
  source                      = "./modules/ec2"
  source_bucket_arn           = module.s3.source_bucket_arn
  log_bucket_name             = var.s3_logs_bucket_name
  sse_algorithm               = var.sse_algorithm
  environment                 = var.environment
  ip_cidr                     = var.ip_cidr
  cognito_user_pool_arn       = module.cognito.cognito_user_pool_arn
  cognito_user_pool_client_id = module.cognito.cognito_user_pool_client_id
  cognito_domain              = module.cognito.cognito_domain

  #depends_on        = [module.s3]
}

/* Create an amazon inspector to scan ec2 instances */
module "cognito" {
  source       = "./modules/cognito"
  environment  = var.environment
  alb_dns_name = module.ec2_webserver.alb_dns_name
  cognito_user = var.email_address
}

/* Create an amazon inspector to scan ec2 instances */
/*module "inspector" {
  source      = "./modules/inspector"
  environment = var.environment
}*/

/* Create an amazon security hub */
/*module "securityhub" {
  source      = "./modules/securityhub"
  environment = var.environment
}*/

/* enable cloutrail */
/*module "cloudtrail" {
  source                 = "./modules/cloudtrail"
  environment            = var.environment
  cloudtrail_bucket_name = var.s3_cloudtrail_bucket_name
}*/
