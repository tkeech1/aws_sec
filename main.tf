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
  logs_bucket_name   = var.s3_logs_bucket_name
  environment        = var.environment
  sse_algorithm      = var.sse_algorithm
}

/* Create an ec2 server with ssh access */
module "ec2_webserver" {
  source            = "./modules/ec2"
  source_bucket_arn = module.s3.source_bucket_arn
  log_bucket_name   = module.s3.logs_bucket_name
  environment       = var.environment
  #depends_on        = [module.s3]
}

/* Create an amazon inspector to scan ec2 instances */
/*module "inspector" {
  source      = "./modules/inspector"
  environment = var.environment
}*/
