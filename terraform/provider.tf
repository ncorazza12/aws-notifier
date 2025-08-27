terraform {
  required_version = ">= 1.11.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9.0"
    }
  }

  backend "s3" {
    bucket  = "bucket-backend-nickolas-denis"
    key     = "aws-notifier/terraform.tfstate"
    region  = "us-east-1"
    profile = "iac"  # opcional se usar localmente
  }
}

provider "aws" {
  region = "us-east-1"
}
