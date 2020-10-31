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

/* Create an ec2 server with ssh access */
/*module "ec2_webserver" {
  source      = "./modules/ec2"
  environment = var.environment
}*/

/* Create an amazon inspector to scan ec2 instances */
/*module "inspector" {
  source      = "./modules/inspector"
  environment = var.environment
}*/

// MWA
/* static s3 web application */
/*module "s3_web" {
  source        = "./modules/s3_web"
  environment   = "mwa"
  sse_algorithm = var.sse_algorithm
  bucket_name   = var.s3_web_bucket_name
}*/

/* mwa application */
/*module "mwa" {
  source      = "./modules/mwa"
  environment = "mwa"
}*/
