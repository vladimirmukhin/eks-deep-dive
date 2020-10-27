#Configure AWS provider and initialize remote backend
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "vlad.terraform"
    key            = "tfstate/"
    region         = "us-east-1"
    dynamodb_table = "terraform"
  }
}

provider "aws" {
  region = "us-east-1"
}

provider kubernetes {
  config_path      = module.eks.kubeconfig_filename
  load_config_file = true
}

#Create a VPC
data "aws_availability_zones" "available" {}

module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.62.0"

  name                 = "eks-sandbox"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "eks" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v12.2.0"

  cluster_name     = var.cluster_name
  subnets          = module.vpc.private_subnets
  vpc_id           = module.vpc.vpc_id
  write_kubeconfig = true

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = "t2.medium"
      asg_desired_capacity = 3
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/${var.cluster_name}",
          "value"               = "owned",
          "propagate_at_launch" = "true"
        }
      ]
    }
  ]
}