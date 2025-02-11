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

resource "docker_image" "garage" {
  provider = docker.selena
  name = "dxflrs/garage:v1.0.0"
  keep_locally = false
}

resource "docker_container" "garage" {
  provider = docker.selena
  name = "garaged"
  image = docker_image.garage.image_id
  
  upload {
    content = templatefile("${path.module}/../../templates/garage/garage.toml.tpl", {
      rpc_secret = var.garage_rpc_secret
      rpc_host = var.garage_rpc_host
    })
    file = "/etc/garage.toml"
  }

  volumes {
    host_path      = "/nvme0n1/garage/meta"
    container_path = "/var/lib/garage/meta"
  }
  volumes {
    host_path      = "/nvme0n1/garage/data"
    container_path = "/var/lib/garage/data"
  }
  
  ports {
    internal = 3900
    external = 3900
  }
  ports {
    internal = 3901
    external = 3901
  }
  ports {
    internal = 3902
    external = 3902
  }
}

resource "docker_image" "ollama" {
  provider = docker.selena
  name = "ollama/ollama:latest"
  keep_locally = false
}

resource "docker_container" "ollama" {
  provider = docker.selena
  name = "ollama"
  image = docker_image.ollama.image_id

  ports {
    internal = 11434
    external = 11434
  }
}


resource "docker_image" "traefik" {
  provider = docker.selena
  name = "traefik:v3.3"
  keep_locally = false
}

data "docker_network" "traefik_internal" {
  provider = docker.selena
  name = "internal"
}

resource "docker_container" "traefik" {
  provider = docker.selena
  name = "traefik"
  image = docker_image.traefik.image_id

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = false
  }
  volumes {
    host_path = "/nvme0n1/data/data/config/traefik/dynamic"
    container_path = "/etc/traefik/dynamic"
  }
  volumes {
    host_path = "/nvme0n1/data/data/config/traefik/certs"
    container_path = "/etc/traefik/certs"
  }

  ports {
    internal = 80
    external = 80
  }
  ports {
    internal = 443
    external = 443
  }
  ports {
    internal = 8080
    external = 8080
  }
  networks_advanced {
    name = data.docker_network.traefik_internal.name
  }

  command = [
    "--api.insecure=true",
    "--providers.docker",
    "--entrypoints.web.address=:80",
    "--entrypoints.websecure.address=:443",
    "--providers.file.directory=/etc/traefik/dynamic",
    "--providers.file.watch=true"
  ]
}

