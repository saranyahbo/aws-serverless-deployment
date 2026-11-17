terraform {
  backend "s3" {
    bucket = "learn-eks-cluster-tfstate-bucket"
    key    = "static-hosting/terraform.tfstate"
    region = "us-east-1"
  }
}