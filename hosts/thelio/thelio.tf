
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
provider "docker" {
  alias = "thelio"
  host = "ssh://nick@192.168.0.30:22"
}


variable "garage_rpc_secret" {
  type        = string
  description = "The secret for the garage RPC"
}

variable "garage_rpc_host" {
  type = string
  description = "The host's IP"
  default = "192.168.0.30"
}

resource "docker_image" "garage" {
  provider = docker.thelio
  name = "dxflrs/garage:v1.0.0"
  keep_locally = false
}

resource "docker_container" "garage" {
  provider = docker.thelio
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
    host_path      = "/media/garaged/meta"
    container_path = "/var/lib/garage/meta"
  }
  volumes {
    host_path      = "/media/garaged/data"
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

resource "docker_image" "traefik" {
  provider = docker.thelio
  name = "traefik:v3.2"
  keep_locally = false
}

resource "docker_network" "traefik_internal" {
  provider = docker.thelio
  name = "traefik_internal"
  attachable = true
  ipam_config {
    subnet  = "10.0.1.0/24"
    gateway = "10.0.1.254"
  }
}

resource "docker_container" "traefik" {
  provider = docker.thelio
  name = "traefik"
  image = docker_image.traefik.image_id

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = false
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
    name = docker_network.traefik_internal.name
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

