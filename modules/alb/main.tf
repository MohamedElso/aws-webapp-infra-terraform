module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  name    = "${var.name_prefix}-alb"
  vpc_id  = var.vpc_id
  subnets = var.subnets
  security_groups = var.security_groups

  target_groups = [{
    name            = "${var.name_prefix}-tg"
    backend_protocol = "HTTP"
    backend_port    = var.container_port
    target_type     = "ip"
    health_check = {
      path = "/"
    }
  }]

  https_listeners = var.domain_name != "" || var.certificate_arn != "" ? [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.certificate_arn
      target_group_index = 0
      ssl_policy         = "ELBSecurityPolicy-2016-08"
    }
  ] : []

  http_tcp_listeners = var.domain_name != "" || var.certificate_arn != "" ? [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ] : [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = var.tags
}
