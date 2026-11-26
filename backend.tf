terraform {
  backend "s3" {
    bucket = "clops-s3-tfstate-bucket"
    key    = "static-hosting/terraform.tfstate"
    region = "us-east-1"
  }
}