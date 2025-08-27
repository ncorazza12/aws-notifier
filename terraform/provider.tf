terraform {
  required_version = "~> 1.12.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9.0"
    }
  }

  backend "s3" {
    bucket         = "bucket-backend-nickolas-denis"
    key            = "aws-notifier/terraform.tfstate" # 🔹 separa o state desse projeto
    region         = "us-east-1"
    profile        = "iac"
    # dynamodb_table = "terraform-locks" # opcional, recomendado p/ evitar concorrência
  }
}

provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["./.aws/config"]
  shared_credentials_files = ["./.aws/credentials"]
  profile                  = "iac"
}
