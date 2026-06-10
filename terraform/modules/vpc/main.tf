# ==============================================================================
# VPC – Milestone 2: Network Isolation for SAST Scanner Lambda
# Architecture:
#   Public Subnet  → Internet Gateway   (NAT Gateway lives here)
#   Private Subnet → NAT Gateway        (Lambda lives here – no direct internet)
# ==============================================================================

resource "aws_vpc" "sast_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, { Name = "sast-pipeline-vpc" })
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.sast_vpc.id
  tags   = merge(var.common_tags, { Name = "sast-igw" })
}

# ── Public Subnet (NAT Gateway lives here) ────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.sast_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = merge(var.common_tags, { Name = "sast-public-subnet" })
}

# ── Private Subnet (Lambda lives here – no inbound from internet) ─────────────
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.sast_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = merge(var.common_tags, { Name = "sast-private-subnet" })
}

# ── Elastic IP for NAT Gateway ────────────────────────────────────────────────
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = merge(var.common_tags, { Name = "sast-nat-eip" })
}

# ── NAT Gateway (public subnet – allows private Lambda outbound access) ────────
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  tags          = merge(var.common_tags, { Name = "sast-nat-gateway" })
  depends_on    = [aws_internet_gateway.igw]
}

# ── Route Table: Public Subnet → IGW ─────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sast_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.common_tags, { Name = "sast-public-rt" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Route Table: Private Subnet → NAT Gateway ────────────────────────────────
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.sast_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = merge(var.common_tags, { Name = "sast-private-rt" })
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ── Security Group for Lambda (allow all outbound, no inbound) ────────────────
resource "aws_security_group" "lambda_sg" {
  name        = "sast-lambda-sg"
  description = "Allow all outbound traffic for SAST Lambda; no inbound"
  vpc_id      = aws_vpc.sast_vpc.id

  egress {
    description = "Allow all outbound (NAT Gateway routes to internet)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "sast-lambda-sg" })
}
