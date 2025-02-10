terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
provider "docker" {
  alias = "harmonia"
  host = "ssh://nick@192.168.0.160:22"
}


variable "garage_rpc_secret" {
  type        = string
  description = "The secret for the garage RPC"
}

variable "garage_rpc_host" {
  type = string
  description = "The host's IP"
  default = "192.168.0.160"
}

resource "docker_image" "garage" {
  provider = docker.harmonia
  name = "dxflrs/garage:v1.0.0"
  keep_locally = false
}

resource "docker_container" "garage" {
  provider = docker.harmonia
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
    host_path      = "/drives-old/data/garage/meta"
    container_path = "/var/lib/garage/meta"
  }
  volumes {
    host_path      = "/drives-old/data/garage/data"
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