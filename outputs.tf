output "public_ip" {
  value = "${aws_elb.example-elb.dns_name}"
}
