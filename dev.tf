/*====
Variables used across all modules
======*/
locals {
  dev_availability_zones = ["${var.region}a", "${var.region}b"]
  environment            = "dev"
}

//*=======Usar somente para pipeline"==========*/
terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "techchallenge-soat1-grp13-state"
    key            = "tfstate-s3-bucket"
    region         = "us-west-2"
    dynamodb_table = "soat1-grp13-dynamo-lock"
  }
}

module "networking" {
  source = "./modules/networking"

  region             = var.region
  environment        = var.environment
  availability_zones = local.dev_availability_zones
}

module "bastion-ec2" {
  source = "./modules/bastion"

  public_subnet = module.networking.public_subnet_id
  vpc_id        = module.networking.vpc_id
  environment   = local.environment
}

module "databases" {
  source = "./modules/database"

  availability_zone      = local.dev_availability_zones[0]
  subnet_group_name      = module.networking.db_subnet_group_name
  db_username            = var.db_username
  db_password            = var.db_password
  environment            = local.environment
  vpc_id                 = module.networking.vpc_id
  bastion_security_group = module.bastion-ec2.bastion_security_group
  ecs_security_group     = module.ecs.ecs_security_group
}

module "s3" {
  source = "./modules/s3"

  environment = local.environment
}

module "secrets" {
  source = "./modules/secrets"
}

module "alb" {
  source = "./modules/alb"

  vpc_id              = module.networking.vpc_id
  privates_subnets_id = module.networking.private_subnet_id
}

module "apigw" {
  source              = "./modules/apigw"
  privates_subnets_id = module.networking.private_subnet_id
  listener_arn        = module.alb.listener_arn
}

module "ecs" {
  source = "./modules/ecs"

  privates_subnets_id           = module.networking.private_subnet_id
  task_exec_secret_arns         = module.secrets.aws_secretsmanager_secret_arn
  lb_engress_id                 = module.alb.egress_all_id
  lb_ingress_id                 = module.alb.ingress_api_id
  lb_target_group_pagamento_arn = module.alb.lb_target_group_pagamento_arn
  lb_target_group_pedido_arn    = module.alb.lb_target_group_pedido_arn
  lb_target_group_producao_arn  = module.alb.lb_target_group_producao_arn
  vpc_id                        = module.networking.vpc_id
}
