provider "aws" {
  region = "us-east-1"
}

# Step 2: Create ECR Repository
resource "aws_ecr_repository" "workshop" {
  name = "workshop"
}

# Step 4: Create ECS Cluster
resource "aws_ecs_cluster" "workshop_cluster" {
  name = "workshop-cluster"
}

# Step 5: Create IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecr_pull_policy" {
  name        = "ECRPullPolicy"
  description = "Policy to allow ECS to pull from ECR"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:us-east-1:438756903535:repository/workshop"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_ecr_pull_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}


# Step 7: Create VPC, Subnet, IGW, Route Table, and Security Group
resource "aws_vpc" "workshop_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "workshop_subnet" {
  vpc_id                  = aws_vpc.workshop_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "workshop_igw" {
  vpc_id = aws_vpc.workshop_vpc.id
}

resource "aws_route_table" "workshop_rt" {
  vpc_id = aws_vpc.workshop_vpc.id
}

resource "aws_route" "workshop_route" {
  route_table_id         = aws_route_table.workshop_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.workshop_igw.id
}

resource "aws_route_table_association" "workshop_rta" {
  subnet_id      = aws_subnet.workshop_subnet.id
  route_table_id = aws_route_table.workshop_rt.id
}

resource "aws_security_group" "ecs_security_group" {
  vpc_id = aws_vpc.workshop_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Step 7: Create VPC Endpoint for ECR (for private connectivity)
resource "aws_vpc_endpoint" "ecr_endpoint" {
  vpc_id            = aws_vpc.workshop_vpc.id
  service_name      = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.workshop_subnet.id]  # Corrected here
}

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id            = aws_vpc.workshop_vpc.id
  service_name      = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.workshop_subnet.id]  # Corrected here
}

# Step 6: Create ECS Task Definition
resource "aws_ecs_task_definition" "workshop_task" {
  family                   = "workshop-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "1024"
  memory                   = "2048"

  container_definitions = jsonencode([
    {
      name  = "workshop-container",
      image = "${aws_ecr_repository.workshop.repository_url}:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80
        }
      ]
    }
  ])
}

# Step 7: Create ECS Service
resource "aws_ecs_service" "workshop_service" {
  name            = "workshop-service"
  cluster         = aws_ecs_cluster.workshop_cluster.id
  task_definition = aws_ecs_task_definition.workshop_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.workshop_subnet.id]
    security_groups = [aws_security_group.ecs_security_group.id]
    assign_public_ip = true
  }
}
