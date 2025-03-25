# Project Docker DevOps Master Class
Simple Python/Flask web application that shows container name and background color


### Steps to Start the Project:

1. Clone the repository using the following command:
   ```
   git clone https://github.com/Chamssiddine/docker-ecs-workshop.git
   ```

2. Navigate to the project directory:
   ```
   cd docker-ecs-workshop
   ```

3.  Open the project in Visual Studio Code:
   ```
   code .
   ```


### Docker Commands:

```bash
docker build . -t workshop:1.0.0
```
- This command builds a Docker image from the current directory (`.`) and tags it as `workshop:1.0.0`.

```bash
docker run -p 8080:8080 --name workshop -d workshop:1.0.0
```
- This command runs a container named `workshop` from the `workshop:1.0.0` image. It maps port 8080 from the host to port 8080 inside the container and `-d` is to run the container in the background.

```bash
docker ps
```
- This command lists all running Docker containers.

```bash
docker stop workshop
```
- This stops the running container named `workshop`.

```bash
docker rm workshop
```
- This removes the container named `workshop`.


# Deploy our Container to AWS

## Prerequisites
- AWS CLI installed and configured
- Terraform installed
- Docker installed



## Step 3: Deploy with Terraform

```sh
# Navigate to the Terraform directory
cd terraform/

# Initialize Terraform
terraform init

# Plan Terraform changes
terraform plan -out workshop

# Apply Terraform changes
terraform apply "workshop"
```

## Step 2: Build and Tag the Docker Image

```sh

# Build the Docker image
docker build --platform linux/amd64 -t workshop .

# Tag the Docker image
docker tag workshop:latest 438756903535.dkr.ecr.us-east-1.amazonaws.com/workshop:latest

# Authenticate Docker with AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 438756903535.dkr.ecr.us-east-1.amazonaws.com

# Push the image to AWS ECR
docker push 438756903535.dkr.ecr.us-east-1.amazonaws.com/workshop:latest
```

## Cleanup
To remove all deployed resources, run:

```sh
terraform destroy -auto-approve
```