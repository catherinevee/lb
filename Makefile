# Makefile for AWS ALB Terraform Module
# This Makefile provides common operations for managing the Terraform module

.PHONY: help init plan apply destroy validate fmt lint clean test examples

# Default target
help:
	@echo "Available commands:"
	@echo "  init      - Initialize Terraform working directory"
	@echo "  plan      - Show Terraform execution plan"
	@echo "  apply     - Apply Terraform changes"
	@echo "  destroy   - Destroy Terraform-managed infrastructure"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform code"
	@echo "  lint      - Run Terraform linting"
	@echo "  clean     - Clean up Terraform files"
	@echo "  test      - Run tests"
	@echo "  examples  - Test examples"

# Initialize Terraform
init:
	terraform init

# Show execution plan
plan:
	terraform plan

# Apply changes
apply:
	terraform apply

# Destroy infrastructure
destroy:
	terraform destroy

# Validate configuration
validate:
	terraform validate

# Format code
fmt:
	terraform fmt -recursive

# Run linting (requires tflint)
lint:
	@if command -v tflint >/dev/null 2>&1; then \
		tflint; \
	else \
		echo "tflint not found. Install with: go install github.com/terraform-linters/tflint/cmd/tflint@latest"; \
	fi

# Clean up
clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate
	rm -f terraform.tfstate.backup

# Run tests (if terratest is available)
test:
	@if command -v go >/dev/null 2>&1; then \
		cd test && go test -v -timeout 30m; \
	else \
		echo "Go not found. Skipping terratest."; \
	fi

# Test examples
examples:
	@echo "Testing basic example..."
	@cd examples/basic && terraform init && terraform validate
	@echo "Testing advanced example..."
	@cd examples/advanced && terraform init && terraform validate
	@echo "All examples validated successfully!"

# Install development dependencies
install-deps:
	@echo "Installing development dependencies..."
	@if command -v go >/dev/null 2>&1; then \
		go install github.com/terraform-linters/tflint/cmd/tflint@latest; \
		go install github.com/gruntwork-io/terratest/modules/terraform@latest; \
	else \
		echo "Go not found. Please install Go to use development tools."; \
	fi

# Check for security issues (requires terrascan)
security-scan:
	@if command -v terrascan >/dev/null 2>&1; then \
		terrascan scan -i terraform; \
	else \
		echo "terrascan not found. Install with: go install github.com/tenable/terrascan/cmd/terrascan@latest"; \
	fi

# Generate documentation
docs:
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table . > README.md.tmp && \
		mv README.md.tmp README.md; \
	else \
		echo "terraform-docs not found. Install with: go install github.com/terraform-docs/terraform-docs@latest"; \
	fi

# Pre-commit checks
pre-commit: fmt validate lint
	@echo "Pre-commit checks completed successfully!" 