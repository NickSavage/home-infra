module "home-gateway" {
  source = "./hosts/home-gateway"
}

module "selena" {
  source = "./hosts/selena"
  garage_rpc_secret = var.garage_rpc_secret
}

module "harmonia" {
  source = "./hosts/harmonia"
  garage_rpc_secret = var.garage_rpc_secret
}

module "thelio" {
  source = "./hosts/thelio"
  garage_rpc_secret = var.garage_rpc_secret
}