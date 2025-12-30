# --- VPC CONFIGURATION ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.prefix}-${var.environment}-vpc"
  }
}

# --- PUBLIC SUBNETS (For Load Balancer) ---
resource "aws_subnet" "public_1" {
  cidr_block              = var.subnet_cidr["public_1"]
  availability_zone       = var.zone1
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  tags = { Name = "${var.environment}-public-1" }
}

resource "aws_subnet" "public_2" {
  cidr_block              = var.subnet_cidr["public_2"]
  availability_zone       = var.zone2
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  tags = { Name = "${var.environment}-public-2" }
}

# --- PRIVATE SUBNETS (For ECS Fargate Tasks) ---
resource "aws_subnet" "private_1" {
  cidr_block        = var.subnet_cidr["private_1"]
  availability_zone = var.zone1
  vpc_id            = aws_vpc.main.id

  tags = { Name = "${var.environment}-private-1" }
}

resource "aws_subnet" "private_2" {
  cidr_block        = var.subnet_cidr["private_2"]
  availability_zone = var.zone2
  vpc_id            = aws_vpc.main.id

  tags = { Name = "${var.environment}-private-2" }
}

# --- DATABASE SUBNETS (For RDS) ---
resource "aws_subnet" "rds_1" {
  cidr_block        = var.subnet_cidr["db_subnet_1"]
  availability_zone = var.zone1
  vpc_id            = aws_vpc.main.id

  tags = { Name = "${var.environment}-rds-1" }
}

resource "aws_subnet" "rds_2" {
  cidr_block        = var.subnet_cidr["db_subnet_2"]
  availability_zone = var.zone2
  vpc_id            = aws_vpc.main.id

  tags = { Name = "${var.environment}-rds-2" }
}

# --- INTERNET GATEWAY ---
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.environment}-igw" }
}

# --- NAT GATEWAYS (For Private Outbound Traffic) ---
resource "aws_eip" "nat_1" {
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "nat-eip-1" }
}

resource "aws_eip" "nat_2" {
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "nat-eip-2" }
}

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "nat-gw-1" }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id
  tags          = { Name = "nat-gw-2" }
}

# --- ROUTE TABLES: PUBLIC ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# --- ROUTE TABLES: PRIVATE (One per AZ for NAT redundancy) ---
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = { Name = "private-rt-1" }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = { Name = "private-rt-2" }
}

# ECS Private Subnet Associations
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

# RDS Private Subnet Associations
resource "aws_route_table_association" "rds_1" {
  subnet_id      = aws_subnet.rds_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "rds_2" {
  subnet_id      = aws_subnet.rds_2.id
  route_table_id = aws_route_table.private_2.id
}
