resource "aws_security_group" "lambda_sg" {
  for_each    = var.lambda_functions
  name        = "${var.application_name}-${each.key}-sg"
  description = "Security group for ${var.application_name}-${each.key} Lambda function"
  vpc_id      = data.aws_vpc.eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}