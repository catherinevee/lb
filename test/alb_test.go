package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestALBModule(t *testing.T) {
	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			// Add any required variables here
		},

		// Environment variables to set
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},

		// Retry on errors
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
		RetryableTerraformErrors: map[string]string{
			"timeout": "Retry on timeout errors",
		},
	})

	// Clean up resources after the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get the ALB DNS name
	albDNSName := terraform.Output(t, terraformOptions, "alb_dns_name")
	albID := terraform.Output(t, terraformOptions, "alb_id")

	// Verify the ALB exists
	assert.NotEmpty(t, albDNSName)
	assert.NotEmpty(t, albID)

	// Verify the ALB is available
	alb := aws.GetApplicationLoadBalancer(t, albID, "us-west-2")
	assert.Equal(t, "active", alb.State.Code)

	// Verify the ALB has the expected attributes
	assert.True(t, alb.EnableHttp2)
	assert.True(t, alb.EnableCrossZoneLoadBalancing)
	assert.Equal(t, int64(60), alb.IdleTimeout)
}

func TestALBModuleWithCustomSettings(t *testing.T) {
	// Configure Terraform options for advanced example
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/advanced",
		Vars:         map[string]interface{}{
			// Add any required variables here
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
	})

	// Clean up resources after the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	albID := terraform.Output(t, terraformOptions, "alb_id")
	targetGroupIDs := terraform.OutputMap(t, terraformOptions, "target_group_ids")

	// Verify the ALB exists
	assert.NotEmpty(t, albID)

	// Verify target groups exist
	assert.NotEmpty(t, targetGroupIDs)
	assert.Contains(t, targetGroupIDs, "frontend-tg")
	assert.Contains(t, targetGroupIDs, "backend-tg")
	assert.Contains(t, targetGroupIDs, "admin-tg")
	assert.Contains(t, targetGroupIDs, "static-tg")
}
