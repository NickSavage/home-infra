terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
provider "docker" {
  alias = "selena"
  host = "ssh://nick@192.168.0.162:22"
}

resource "docker_image" "metube" {
  provider = docker.selena
  name = "ghcr.io/alexta69/metube:latest"
  keep_locally = false
}

resource "docker_container" "metube" {
  provider = docker.selena
  name = "metube"
  image = docker_image.metube.image_id

  ports {
    internal = 8081
    external = 8091
  }
  volumes {
    host_path      = "/home/media/downloads"
    container_path = "/downloads"
  }
}