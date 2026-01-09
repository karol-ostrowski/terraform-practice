variable "cluster_name" {
  description = "name for all cluster resources"
  type = string
}

variable "db_remote_state_bucket" {
  description = "db remote state bucket name"
  type = string
}

variable "db_remote_state_key" {
  description = "path for db remote state in s3"
  type = string
}

variable "backend_key" {
  description = "path for s3 backend"
  type = string
}

variable "instance_type" {
  description = "type of EC2 instance"
  type = string
}

variable "max_size" {
  description = "max size of instances in an asg"
  type = number
}

variable "min_size" {
  description = "min size of instances in an asg"
  type = number
}
