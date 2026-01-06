provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-xd1"
    key = "workspaces-example/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}

resource "aws_instance" "example" {
  ami = "ami-068c0051b15cdb816"
  instance_type = "t2.micro"
}

output "s3_bucket_arn" {
  value = "terraform-up-and-running-state-xd1"
  description = "s3 arn"
}

output "dynamodb_table_name" {
  value = "terraform-up-and-running-locks"
  description = "dynamodb table name"
}
