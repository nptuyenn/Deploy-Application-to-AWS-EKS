terraform {
  backend "s3" {
    bucket         = "todo-terraform-state-10101010"
    region         = "us-east-1"
    key            = "todo-project/EKS-TF/terraform.tfstate"
    dynamodb_table = "todo-terraform-locks"
    encrypt        = true
  }
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source  = "hashicorp/aws"
    }
  }
}