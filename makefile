# Makefile for AWS Account Provisioning System

.PHONY: help install deploy-backend deploy-frontend test clean

# Configuration
AWS_REGION ?= us-east-1
STACK_NAME ?= account-provisioner
FRONTEND_BUCKET ?= account-provisioner-ui-$(shell aws sts get-caller-identity --query Account --output text)

help:
	@echo "Available targets:"
	@echo "  install         - Install all dependencies"
	@echo "  deploy-backend  - Deploy backend services (Lambda, API Gateway, DynamoDB)"
	@echo "  deploy-frontend - Build and deploy frontend application"
	@echo "  deploy-all      - Deploy entire system"
	@echo "  test            - Run tests"
	@echo "  clean           - Remove deployed resources"
	@echo "  status          - Show deployment status"

install:
	@echo "Installing dependencies..."
	# Backend dependencies
	cd backend/provisioning && pip install -r requirements.txt -t ./package
	cd backend/status-checker && pip install -r requirements.txt -t ./package
	# Frontend dependencies
	cd frontend && npm install

deploy-backend:
	@echo "Deploying backend services..."
	# Initialize Terraform
	cd infrastructure && terraform init
	# Apply Terraform configuration
	cd infrastructure && terraform apply -auto-approve \
		-var="aws_region=$(AWS_REGION)" \
		-var="stack_name=$(STACK_NAME)"
	# Deploy SAM application
	cd backend/provisioning && sam build
	cd backend/provisioning && sam deploy --guided --region $(AWS_REGION)
	# Get API endpoint
	@echo "API Endpoint: $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' --output text)"

deploy-frontend:
	@echo "Deploying frontend application..."
	# Build React app
	cd frontend && npm run build
	# Create S3 bucket if not exists
	@aws s3api head-bucket --bucket $(FRONTEND_BUCKET) 2>/dev/null || \
		aws s3 mb s3://$(FRONTEND_BUCKET) --region $(AWS_REGION)
	# Upload files
	aws s3 sync frontend/build s3://$(FRONTEND_BUCKET)
	# Enable static website hosting
	aws s3 website s3://$(FRONTEND_BUCKET) --index-document index.html --error-document index.html
	# Set bucket policy
	aws s3api put-bucket-policy --bucket $(FRONTEND_BUCKET) --policy "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":[\"s3:GetObject\"],\"Resource\":[\"arn:aws:s3:::$(FRONTEND_BUCKET)/*\"]}]}"
	@echo "Frontend deployed to: http://$(FRONTEND_BUCKET).s3-website-$(AWS_REGION).amazonaws.com"

deploy-all: install deploy-backend deploy-frontend

test:
	@echo "Running tests..."
	cd frontend && npm test

clean:
	@echo "Cleaning up resources..."
	# Delete SAM stack
	aws cloudformation delete-stack --stack-name $(STACK_NAME)
	# Empty and delete S3 bucket
	aws s3 rm s3://$(FRONTEND_BUCKET) --recursive
	aws s3 rb s3://$(FRONTEND_BUCKET)
	# Destroy Terraform resources
	cd infrastructure && terraform destroy -auto-approve \
		-var="aws_region=$(AWS_REGION)" \
		-var="stack_name=$(STACK_NAME)"

status:
	@echo "Backend Stack Status:"
	@aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].StackStatus' --output text
	@echo "\nFrontend Bucket: http://$(FRONTEND_BUCKET).s3-website-$(AWS_REGION).amazonaws.com"
