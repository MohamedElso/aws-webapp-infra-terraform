output "service_name" {
  value = aws_ecs_service.service.name
}

output "service_arn" {
  value = aws_ecs_service.service.arn
}
