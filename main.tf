module "vnet" {
  source = "./modules/vnet"
}


/*
module "bastion" {
  source             = "./modules/bastion"
  vnet_id            = module.vnet.vnet_id
  dmz_subnet_id      = module.vnet.dmz_subnet_id
  web_subnet_id      = module.vnet.web_subnet_id
  business_subnet_id = module.vnet.business_subnet_id
  data_subnet_id     = module.vnet.data_subnet_id
  bastion_subnet_id  = module.vnet.bastion_subnet_id
}
*/

/*
module "webservers" {
  source        = "./modules/webservers"
  web_subnet_id = module.vnet.web_subnet_id
}
*/

/*
module "business-servers" {
  source              = "./modules/business-servers"
  business_subnet_id     = module.vnet.business_subnet_id
}
*/

/*
module "database" {
  source = "./modules/database"
}
*/

/*
module "firewall" {
  source        = "./modules/firewall"
  dmz_subnet_id = module.vnet.dmz_subnet_id
}
*/