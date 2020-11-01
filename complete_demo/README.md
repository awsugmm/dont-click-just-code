## Requirements

| Name | Version |
|------|---------|
| terraform | ~> v0.13.4 |
| aws | >= 3.9.0 |
| null | >= 2.1.2 |
| random | >= 2.3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.9.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| profile | n/a | `string` | `"awsugmm"` | no |
| region | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| elb\_dns\_name | DNS Name of the ELB |
| web\_domain | n/a |

