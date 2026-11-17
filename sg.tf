resource "aws_security_group" "lambda_sg" {
  for_each    = var.lambda_functions
  name        = "${each.value.function_name}-sg"
  description = "Security group for ${each.value.function_name} Lambda function"
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