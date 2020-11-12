
/* mwa application */
module "mwa" {
  source               = "./infrastructure"
  environment          = "mwa"
  region               = var.region
  cognito_user_pool_id = module.mwa_cognito.cognito_user_pool_id
}

// create an ecr registry
module "mwa_ecr" {
  source      = "./ecr"
  environment = "mwa"
}

// create a dynamodb table
module "mwa_dynamodb" {
  source      = "./dynamodb"
  environment = "mwa"
}

module "mwa_s3web" {
  source        = "./s3_web"
  environment   = var.environment
  bucket_name   = var.s3_web_bucket_name
  sse_algorithm = var.sse_algorithm
}

module "mwa_cognito" {
  source      = "./cognito"
  environment = "mwa"
}
