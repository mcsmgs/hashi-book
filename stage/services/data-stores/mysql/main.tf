provider "aws" {
  region = "eu-west-2"
}

resource "aws_db_instance" "example_db" {
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "example_database"
  username          = "admin"
  password          = "${var.db_password}"
}

terraform {
  backend "s3" {
    bucket = "terraform-s3-bucket-tfstate"
    key    = "state/services/data-stores/mysql/terraform.tfstate"
    region = "eu-west-2"
  }
}
