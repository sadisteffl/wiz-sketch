# --- Networking Resources ---

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "wiz-exercise-vpc"
  }
}

resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "wiz-exercise-public-subnet-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "wiz-exercise-public-subnet-az2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "wiz-exercise-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "wiz-exercise-public-rt"
  }
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "k8s_cluster" {
  name        = "k8s-cluster-sg"
  description = "Security group for K8s worker nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "wiz-exercise-k8s-sg"
  }
}

resource "aws_security_group" "db_vm" {
  name        = "db-vm-sg"
  description = "Allow SSH from public and DB traffic from K8s"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from Internet"
  }

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.k8s_cluster.id]
    description     = "Allow MongoDB traffic from K8s"
  }

  tags = {
    Name = "wiz-exercise-db-vm-sg"
  }
}