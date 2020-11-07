
// create the ecs cluster
module "mwa_ecs" {
  source                = "./ecs"
  ecs_role_arn          = module.mwa.mwa_ecs_role_arn
  ecs_task_role_arn     = module.mwa.mwa_ecs_task_role_arn
  ecr_image_tag         = "${module.mwa_ecr.ecr_repository_url}:latest"
  security_group_id     = module.mwa.mwa_security_group_id
  private_subnet_one_id = module.mwa.mwa_public_subnet_one_id
  private_subnet_two_id = module.mwa.mwa_public_subnet_two_id
  target_group_arn      = module.mwa.mwa_target_group_arn
  environment           = "mwa"
}
