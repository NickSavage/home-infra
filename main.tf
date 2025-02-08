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

# Create a directory for nginx configuration
resource "docker_volume" "nginx_config" {
  name = "nginx_config"
}

resource "docker_image" "nginx" {
  provider = docker.terraform-test-ct
  name = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "container_host1" {
  provider = docker.terraform-test-ct
  name     = "nginx"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 80
  }

  ports {
    internal = 443
    external = 443
  }

  upload {
    content = file("${path.module}/nginx/default.conf")
    file    = "/etc/nginx/conf.d/default.conf"
  }
}
