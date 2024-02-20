terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
    backend "s3" {
      bucket         = "terraform-remote-state-bucket-188721"
      key            = "terraform-remote-state"
      region         = "ap-southeast-1"
      dynamodb_table = "terraform-remote-state-lock"
      encrypt        = true
    }
  }
  
  provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
  }