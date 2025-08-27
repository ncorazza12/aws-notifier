##################################################
# PROVIDER E BACKEND
##################################################

terraform {
  required_version = "~> 1.12.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9.0"
    }
  }

  backend "s3" {
    bucket  = "bucket-backend-nickolas-denis"
    key     = "aws-notifier/terraform.tfstate"  # separa do outro projeto
    region  = "us-east-1"
    profile = "iac"
    # dynamodb_table = "terraform-locks"  # opcional para state locking
  }
}

provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["./.aws/config"]
  shared_credentials_files = ["./.aws/credentials"]
  profile                  = "iac"
}

##################################################
# ORCHESTRATOR - MÓDULOS
##################################################

module "rede" {
  source               = "./modules/rede"
  vpc_cidr             = var.vpc_cidr
  vpc_az1              = var.vpc_az1
  vpc_az2              = var.vpc_az2
  vpc_sn_pub_az1_cidr  = var.vpc_sn_pub_az1_cidr
  vpc_sn_pub_az2_cidr  = var.vpc_sn_pub_az2_cidr
  vpc_sn_priv_az1_cidr = var.vpc_sn_priv_az1_cidr
  vpc_sn_priv_az2_cidr = var.vpc_sn_priv_az2_cidr
}

module "dados" {
  source               = "./modules/dados"
  rds_identifier       = var.rds_identifier
  rds_engine_version   = var.rds_engine_version
  rds_sn_group_name    = var.rds_sn_group_name
  rds_param_group_name = var.rds_param_group_name
  rds_dbname           = var.rds_dbname
  rds_dbuser           = var.rds_dbuser
  rds_dbpassword       = var.rds_dbpassword
  vpc_cidr             = var.vpc_cidr
  vpc_id               = module.rede.vpc_id
  vpc_sn_priv_az1_id   = module.rede.vpc_sn_priv_az1_id
  vpc_sn_priv_az2_id   = module.rede.vpc_sn_priv_az2_id
}

module "compute" {
  source                   = "./modules/compute"
  ec2_lt_name              = var.ec2_lt_name
  ec2_lt_ami               = var.ec2_lt_ami
  ec2_lt_instance_type     = var.ec2_lt_instance_type
  ec2_lt_ssh_key_name      = var.ec2_lt_ssh_key_name
  ec2_lb_name              = var.ec2_lb_name
  ec2_lb_tg_name           = var.ec2_lb_tg_name
  ec2_asg_name             = var.ec2_asg_name
  ec2_asg_desired_capacity = var.ec2_asg_desired_capacity
  ec2_asg_min_size         = var.ec2_asg_min_size
  ec2_asg_max_size         = var.ec2_asg_max_size
  vpc_cidr                 = var.vpc_cidr
  vpc_id                   = module.rede.vpc_id
  vpc_sn_pub_az1_id        = module.rede.vpc_sn_pub_az1_id
  vpc_sn_pub_az2_id        = module.rede.vpc_sn_pub_az2_id
  rds_endpoint             = module.dados.rds_endpoint
  rds_dbuser               = var.rds_dbuser
  rds_dbpassword           = var.rds_dbpassword
  rds_dbname               = var.rds_dbname
}
