provider "aws" {
  region = "eu-west-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-s3-bucket-tfstate"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-s3-bucket-tfstate"
    key    = "terraform/chapter3"
    region = "eu-west-2"
  }
}
