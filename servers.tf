

resource "aws_security_group" "server" {
  name        = "localstack-server"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.Network.vpc_id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    description = "allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "aws_security_group" "web_server" {
  name        = "localstack-web-server"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.Network.vpc_id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    description = "allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 4096

}
resource "aws_key_pair" "server" {
  key_name   = "app"
  public_key = tls_private_key.server.public_key_openssh
}

resource "aws_instance" "PublicServer" {
  count                  = var.server_count_public
  ami                    = "ami-123456"
  key_name               = aws_key_pair.server.key_name
  instance_type          = var.server_type
  subnet_id              = module.Network.public_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.server.id]

  #associate_public_ip_address = var.include_ipv4

  tags = {
    Name        = "PublicServer-${count.index}"
    Environment = "localstack"
  }
}

resource "aws_instance" "PrivateServer" {
  count                  = var.server_count_private
  ami                    = "ami-123456"
  key_name               = aws_key_pair.server.key_name
  instance_type          = var.server_type
  subnet_id              = module.Network.private_subnets[count.index]
  vpc_security_group_ids = [aws_security_group.web_server.id]
  user_data              = <<-EOF
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install -y nginx
  sudo systemctl start nginx
  sudo systemctl enable nginx
  EOF

  tags = {
    Name        = "PrivateServer-${count.index}"
    Environment = "localstack"
  }
}

resource "aws_lb" "localstack" {
  name               = "localstack-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server.id]
  subnets            = module.Network.public_subnets

  enable_deletion_protection = false


  tags = {
    name = "localstack-lb-tf"
  }
}

resource "aws_lb_target_group" "localstack" {
  name     = "localstack-lb-tf"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.Network.vpc_id
}


resource "aws_lb_listener" "localstack" {
  load_balancer_arn = aws_lb.localstack.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.localstack.arn
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.localstack.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.localstack.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }

}

resource "aws_lb_target_group_attachment" "localstack" {
  count            = var.server_count_private
  target_group_arn = aws_lb_target_group.localstack.arn
  target_id        = aws_instance.PrivateServer[count.index].id
  port             = 80
}