# ============================================================== eip-manager ===

variable "pool_tag_key" {
  type        = string
  description = <<-EOF
    Tag key used to identify the Elastic IPs (EIPs) that the EIP manager service can assign to EC2 instances. EIPs with
    this tag are considered part of the EIP pool.
  EOF
  default     = "eip-manager-pool"
}

variable "pool_tag_values" {
  type        = list(string)
  description = <<-EOF
    List of tag values that, when paired with the pool_tag_key, identifies the Elastic IPs that the EIP manager can
    assign. Each tag value defines a separate EIP pool.
  EOF
  default     = ["unset"]
}
