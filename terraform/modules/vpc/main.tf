###################################
# Create an Elastic IP for the NAT
###################################
resource "aws_eip" "nat_eip" {
  vpc = true
  depends_on = [
    aws_internet_gateway.igw
  ]
}

###################################
# NAT Gateway
###################################
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id  # Place NAT in the first public subnet
  depends_on    = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "${var.environment_name}-natgw"
  }
}

###################################
# Private Route Table
###################################
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment_name}-private-rt"
  }
}

###################################
# Associate Private Subnets with Private Route Table
###################################
resource "aws_route_table_association" "private_rta" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

###################################
# Route to NAT Gateway
###################################
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

###################################
# VPC
###################################
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.environment_name}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

###################################
# Public Subnets
###################################
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-public-subnet-${count.index}"
  }
}

###################################
# Private Subnets
###################################
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  
  tags = {
    Name = "${var.environment_name}-private-subnet-${count.index}"
  }
}

###################################
# Internet Gateway (for Public Subnets)
###################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment_name}-igw"
  }
}

###################################
# Public Route Table + Route to IGW
###################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment_name}-public-rt"
  }
}

resource "aws_route" "default_public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rta" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

###################################
# Outputs
###################################
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public_subnets : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private_subnets : s.id]
}
