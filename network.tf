#Network
/*
Componentes de Red:
-VPC:10.0.0.0/16  net
-Subnet 1: 10.0.10.0/24
-Subnet 2: 10.0.10.0/24
-Subnet 3: 10.0.10.0/24

-Internet Gateway
-tabla de enrutamiento entre subnet y GW
*/

#Module VPC

module "Network" {
  source = "terraform-aws-modules/vpc/aws"

  name = "network"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true


  tags = {
    Terraform   = "true"
    Environment = "myapp"
  }
}
