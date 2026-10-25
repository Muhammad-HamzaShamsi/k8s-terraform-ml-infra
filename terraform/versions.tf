terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  # Uncomment to keep state in S3 with DynamoDB locking (recommended for teams).
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "ml-infra/terraform.tfstate"
  #   region         = "eu-central-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}
