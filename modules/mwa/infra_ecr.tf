
/* mwa application */
module "mwa" {
  source      = "./infrastructure"
  environment = "mwa"
}

// create an ecr registry
module "mwa_ecr" {
  source      = "./ecr"
  environment = "mwa"
}

