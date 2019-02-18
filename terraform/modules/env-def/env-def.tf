# NOTE: This is the environment definition that will be used by all environments.
# The actual environments (like dev) just inject their environment dependent values to env-def which defines the actual environment and creates that environment using given values.



# You can use Resource groups to find resources. See AWS Console => Resource Groups => Saved.
module "resource-groups" {
  source           = "../resource-groups"
  prefix           = "${var.prefix}"
  env              = "${var.env}"
  region           = "${var.region}"
}


module "vpc" {
  source          = "../vpc"
  prefix          = "${var.prefix}"
  env             = "${var.env}"
  region          = "${var.region}"

  vpc_cidr_block    = "${var.vpc_cidr_block}"
  app_subnet_cidr_block = "${var.app_subnet_cidr_block}"
}


module "ec2" {
  source           = "../ec2"
  prefix           = "${var.prefix}"
  env              = "${var.env}"
  region           = "${var.region}"
  vpc_id           = "${module.vpc.vpc_id}"
  app_subnet_id    = "${module.vpc.app_subnet_id}"
  app_subnet_sg_id = "${module.vpc.app_subnet_sg_id}"
}
