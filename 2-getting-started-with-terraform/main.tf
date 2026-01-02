provider "aws" {
  region = "eu-north-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0b46816ffa1234887"
  instance_type = "t3.nano"

  tags = {
    Name = "terraform-example"
  }
}
