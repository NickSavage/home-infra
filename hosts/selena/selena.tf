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
variable "garage_rpc_secret" {
  type        = string
  description = "The secret for the garage RPC"
}

variable "garage_rpc_host" {
  type = string
  description = "The host's IP"
  default = "192.168.0.162"
}

resource "local_file" "garage_config" {
  content = templatefile("${path.module}/../../templates/garage/garage.toml.tpl", {
    rpc_secret = var.garage_rpc_secret
    rpc_host = var.garage_rpc_host
  })
  filename = "${path.module}/garage/garage.toml"
}