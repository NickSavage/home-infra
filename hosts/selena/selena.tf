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

data "docker_network" "existing_network" {
  provider = docker.selena
  name = "internal"
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
  networks_advanced {
    name = data.docker_network.existing_network.name
  }
  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.metube.rule"
    value = "Host(`metube.thesavages.ca`)"
  }
  labels {
    label = "traefik.http.routers.metube.entrypoints"
    value = "web"
  }
  labels {
    label = "traefik.http.services.metube.loadbalancer.server.port"
    value = "8081"
  }

}