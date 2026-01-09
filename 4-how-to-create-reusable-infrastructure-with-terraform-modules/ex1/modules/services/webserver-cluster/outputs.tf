output "asg_name" {
  value = aws_autoscaling_group.example.name
  description = "asg name"
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
  description = "lb domain name"
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
  description = "alb security group id"
}
