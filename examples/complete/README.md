# Example: Complete

This directory contains a complete example of how to use the AWS EIP Manager
Terraform module in a real-world scenario.

## Overview

This example deploys the following resources:

- Two pools of Elastic IPs (EIPs) for use by the EIP manager
- An EIP manager service that automatically assigns EIPs from the pools to EC2
  instances when they start, and disassociates EIPs when instances stop or
  terminate
- Two Auto Scaling groups (ASGs), each with a different instance type and tag
  indicating which EIP pool they should use
- A security group that allows all traffic within the group

The EIP manager service listens to EC2 instance state change notifications and
manages EIP assignments based on the tags on the instances.

## Usage

To run this example, run as-is or provide your own values for the following
variables in a `.terraform.tfvars` file:

```hcl
vpc_id         = "vpc-00000000000000"
vpc_subnet_ids = ["subnet-00000000000000", "subnet-11111111111111111", "subnet-22222222222222222"]
```

## Inputs

| Name           | Description                                     | Type           | Default | Required |
|----------------|-------------------------------------------------|----------------|---------|:--------:|
| vpc_id         | VPC ID to deploy example resources into.        | `string`       | n/a     |   yes    |
| vpc_subnet_ids | VPC subnet ID to deploy example resources into. | `list(string)` | n/a     |   yes    |

## Outputs

_No outputs at this time._
