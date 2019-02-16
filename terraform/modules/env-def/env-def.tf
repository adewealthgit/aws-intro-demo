# NOTE: This is the environment definition that will be used by all environments.
# The actual environments (like dev) just inject their environment dependent values to env-def which defines the actual environment and creates that environment using given values.


module "vpc" {
  source          = "../vpc"
  prefix          = "${var.prefix}"
  env             = "${var.env}"
  region          = "${var.region}"

  vpc_cidr_block    = "${var.vpc_cidr_block}"
  app_subnet_cidr_block = "${var.app_subnet_cidr_block}"
}

