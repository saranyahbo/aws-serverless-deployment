data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["clops-vpc"]
  }
}

data "aws_subnets" "routable-subnets" {
  filter {
    name   = "tag:Name"
    values = ["routable*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "availability-zone"
    values = var.preferred_azs
  }
}

data "aws_subnets" "non-routable-subnets" {
  filter {
    name   = "tag:Name"
    values = ["non-routable*"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}