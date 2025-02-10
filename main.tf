module "home-gateway" {
  source = "./hosts/home-gateway"
}

module "selena" {
  source = "./hosts/selena"
  garage_rpc_secret = var.garage_rpc_secret
}
