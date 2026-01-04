data "aws_launch_template" "simple-server" {
  name = "sdfsdfv6"
}

resource "aws_instance" "example" {
  launch_template {
    id      = data.aws_launch_template.simple-server.id
    version = "$Latest"
  }
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "public ip of the server"
}
