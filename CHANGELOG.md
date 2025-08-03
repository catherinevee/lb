# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-08-03

### Added
- Initial release of Network Load Balancer module
- Support for TCP and TLS listeners
- Target group health checks
- Cross-zone load balancing configuration
- IPv4 and dualstack support
- Examples for basic TCP and TLS configurations
- Terraform tests for validation
- Comprehensive documentation

### Changed
- Converted from Application Load Balancer to Network Load Balancer
- Updated required provider version to AWS 6.2.0
- Updated Terraform version requirement to 1.13.0
- Updated Terragrunt version requirement to 0.84.0

### Removed
- Application Load Balancer specific configurations
- HTTP/HTTPS specific features
- WAF integration (not supported with NLB)
- Security group associations (not needed for NLB)
