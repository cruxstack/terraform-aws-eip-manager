variable "vpc_id" {
  type        = string
  description = "VPC ID to deploy example resources into."
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "VPC subnet ID to deploy example resources into."
}
