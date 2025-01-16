output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}
