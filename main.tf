provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "example1" {
  ami           = "ami-e6768381"
  instance_type = "t2.micro"

  tags {
    Name = "terraform-example1"
  }
}
