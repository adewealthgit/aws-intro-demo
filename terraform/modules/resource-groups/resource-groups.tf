locals {
  my_env   = "${var.prefix}-${var.env}"
}

# Create the following resource groups for finding resources.
# See AWS Console => Resource groups.

module "rg_env" {
  source        = "resource-group"
  prefix        = "${var.prefix}"
  name          = "env-rg"
  tag_key       = "Env"
  tag_value     = "${var.env}"
  env           = "${var.env}"
}

module "rg_environment" {
  source        = "resource-group"
  prefix        = "${var.prefix}"
  name          = "environment-rg"
  tag_key       = "Environment"
  tag_value     = "${local.my_env}"
  env           = "${var.env}"
}

module "rg_prefix" {
  source        = "resource-group"
  prefix        = "${var.prefix}"
  name          = "prefix-rg"
  tag_key       = "Prefix"
  tag_value     = "${var.prefix}"
  env           = "${var.env}"
}


module "rg_terraform" {
  source        = "resource-group"
  prefix        = "${var.prefix}"
  name          = "terraform-rg"
  tag_key       = "Terraform"
  tag_value     = "true"
  env           = "${var.env}"
}

module "rg_region" {
  source        = "resource-group"
  prefix        = "${var.prefix}"
  name          = "region-rg"
  tag_key       = "Region"
  tag_value     = "${var.region}"
  env           = "${var.env}"
}



