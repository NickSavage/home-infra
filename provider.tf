terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  alias = "terraform-test-ct"
  host = "ssh://nick@192.168.0.25:22"
}