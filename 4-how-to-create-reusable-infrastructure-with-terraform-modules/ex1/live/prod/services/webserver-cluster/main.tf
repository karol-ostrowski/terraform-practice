provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "webservers-prod"
  db_remote_state_bucket = "terraform-up-and-running-state-xd3"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
  backend_key = "prod/services/webserver-cluster/terraform.tfstate"
  instance_type = "t2.micro"
  max_size = 3
  min_size = 2
}
