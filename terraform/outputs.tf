output "lb_dns_name" {
  value       = aws_lb.test.dns_name
  description = "ALB domain"
}