variable "aws_profile" {
  type = string
  default = "default"
}

variable "aws_region" {
  type = string
}

variable "ssh_public_key" {
  type = string
  sensitive   = true
}