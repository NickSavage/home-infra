module "terraform-test" {
  source = "./hosts"
  providers = {
    docker.terraform-test-ct = docker.terraform-test-ct
  }
}