###############################
# MODULE: VPC
###############################
module "vpc" {
  source           = "./modules/vpc"
  environment_name = var.environment_name
  vpc_cidr_block   = var.vpc_cidr_block
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
}

###############################
# MODULE: RDS (Postgres)
###############################
# Use a dedicated Postgres service
module "rds" {
  source             = "./modules/rds"
  environment_name   = var.environment_name
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids
  // pass the same VPC ID from the vpc module
  vpc_id = module.vpc.vpc_id
  vpc_security_group_ids = []
}

###############################
# MODULE: ECS + ALB
###############################
module "ecs" {
  source                = "./modules/ecs"
  environment_name      = var.environment_name
  container_image       = var.ecr_repository_url
  container_port        = var.container_port
  db_host               = module.rds.db_endpoint
  db_name               = var.db_name
  db_user               = var.db_username
  db_password           = var.db_password
  vpc_id                = module.vpc.vpc_id
  public_subnets        = module.vpc.public_subnet_ids
  private_subnets       = module.vpc.private_subnet_ids
}

