# Terraform Module: AWS EIP Manager

This Terraform module deploys a service that manages the assignment of a pool of
Elastic IP (EIP) addresses to AWS EC2 instances. It's based on the [binxio/ec2-elastic-ip-manager](https://github.com/binxio/ec2-elastic-ip-manager)
service with a few modifications.

The service operates by listening to EC2 instance state change notifications.
When an instance reaches the "running" state and is tagged with a specific pool
tag, the service assigns an available EIP from the pool to the instance. If an
instance is stopped or terminated, any EIPs associated with that instance are
disassociated, returning to the pool for use by other instances.

### Features

- **Auto-Assignment of EIPs**: Automatically assigns Elastic IPs (EIPs) from a
  defined pool to EC2 instances when they reach the "running" state.
- **Auto-Release of EIPs**: Automatically disassociates EIPs from instances when
they are stopped or terminated, returning the EIPs back to the pool.
- **Tag-Based EIP Pools**: Uses tags to define pools of EIPs. Each pool can have
  multiple EIPs, and instances can be assigned an EIP from a specific pool based
  on their tags.
- **Scalable**: Can manage multiple EIP pools, allowing for different sets of
  instances to have their EIPs managed independently.
- **Robust Error Handling**: Includes error handling for API calls, ensuring
  that the service continues to operate even when individual actions fail.

## Usage

```hcl
module "eip_manager" {
  source  = "cruxstack/eip-manager/aws"
  version = "x.x.x"

  pool_tag_key    = "your-pool-tag-key"
  pool_tag_values = ["your-pool-tag-value"]
}
```

## Inputs

In addition to the variables documented below, this module includes several
other optional variables (e.g., `name`, `tags`, etc.) provided by the
`cloudposse/label/null` module. Please refer to the [`cloudposse/label` documentation](https://registry.terraform.io/modules/cloudposse/label/null/latest) for more details on these variables.

| Name              | Description                                                                                                                                                           | Type           | Default              | Required |
|-------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|----------------------|:--------:|
| `pool_tag_key`    | Tag key used to identify the Elastic IPs (EIPs) that the EIP manager service can assign to EC2 instances. EIPs with this tag are considered part of the EIP pool.     | `string`       | `"eip-manager-pool"` |    no    |
| `pool_tag_values` | List of tag values that, when paired with the `pool_tag_key`, identifies the Elastic IPs that the EIP manager can assign. Each tag value defines a separate EIP pool. | `list(string)` | `["unset"]`          |    no    |

### Outputs

| Name                  | Description                                                     |
|-----------------------|-----------------------------------------------------------------|
| `lambda_function_arn` | The ARN of the EIP manager Lambda function                      |
| `iam_role_arn`        | The ARN of the IAM role used by the EIP manager Lambda function |

## Contributing

We welcome contributions to this project. For information on setting up a
development environment and how to make a contribution, see [CONTRIBUTING](./CONTRIBUTING.md)
documentation.
