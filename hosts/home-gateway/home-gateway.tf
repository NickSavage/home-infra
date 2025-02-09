terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  alias = "home-gateway"
  host = "ssh://nick@home-gateway:22"
}

resource "docker_image" "nginx" {
  provider = docker.home-gateway
  name = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  provider = docker.home-gateway
  name = "nginx"
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
  volumes {
    host_path      = "/etc/letsencrypt"
    container_path = "/etc/letsencrypt"
    read_only      = true
  }
  volumes {
    host_path      = "/var/log/nginx"
    container_path = "/var/log/nginx"
    read_only      = false
  }
}