terraform {
  backend "remote" {
    organization = "wiz-sketch-ai"

    workspaces {
      name = "wiz-sketch"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.13"
    }
  }
}
