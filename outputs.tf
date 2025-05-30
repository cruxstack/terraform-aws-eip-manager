output "lambda_function_arn" {
  description = "The ARN of the EIP manager Lambda function"
  value       = module.this.enabled ? aws_lambda_function.this[0].arn : ""
}

output "iam_role_arn" {
  description = "The ARN of the IAM role used by the EIP manager Lambda function"
  value       = module.this.enabled ? aws_iam_role.this[0].arn : ""
}
