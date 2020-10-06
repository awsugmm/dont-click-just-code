terraform {
  required_version = "~> v0.13.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.1.2"
    }
    random = {
      resource = "hashicorp/random"
      version  = ">= 2.3.0"
    }
  }
}
