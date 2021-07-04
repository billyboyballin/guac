variable "region" {
  type        = string
  description = "AWS region to deploy in"
}

variable "ssh_key_name" {
  type        = string
  description = "aws ssh key"
}

variable "secrets" {
  type = object({
    aws_access_key_id     = string
    aws_secret_access_key = string
  })
  sensitive = true
}
