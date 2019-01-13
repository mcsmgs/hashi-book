provider "aws" {
  region = "eu-west-2"
}

module "webserver_cluster" {
  source = "/Users/mdasilva/gitrepo/terraform-book/modules/services/webserver-cluster"

  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "Lesson stopped here"
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "terraform-s3-bucket-tfstate"
    key    = "state/services/data-stores/mysql/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "template_file" "user_data" {
  template = "${file("user_data.sh")}"

  vars {
    server_port = "${var.server_port}"
    db_address  = "${data.terraform_remote_state.db.address}"
    db_port     = "${data.terraform_remote_state.db.port}"
  }
}

/*
resource "aws_instance" "example-ec2" {
  ami                    = "ami-e6768381"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
							#!/bin/bash
							echo "Hello, World" > index.html
							nohup busybox httpd -f -p 8080 &
							EOF

  tags {
    Name = "terraform-example-ec2"
  }
}
*/
resource "aws_launch_configuration" "example-lc" {
  image_id        = "ami-e6768381"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data       = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example-asg" {
  launch_configuration = "${aws_launch_configuration.example-lc.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.example-elb.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tags {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example-elb" {
  name               = "terraform-asg-example-elb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-sc-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-sc-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-s3-bucket-tfstate"
    key    = "state/services/webserver-cluster/terraform.tfstate"
    region = "eu-west-2"
  }
}
