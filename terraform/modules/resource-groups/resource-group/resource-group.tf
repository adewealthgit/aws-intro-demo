locals {
  # Group name cannot start with "aws".
  my_name   = "rg-${var.prefix}-${var.env}-${var.name}"
  my_env    = "${var.env}"
}

resource "aws_resourcegroups_group" "rg" {
  name = "${local.my_name}"
  description = "Filter-tag is ${var.tag_key} and Filter-value is ${var.tag_value}"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": ["AWS::AllSupported"],

  "TagFilters": [
    {
      "Key": "${var.tag_key}",
      "Values": ["${var.tag_value}"]
    }
  ]
}
JSON
  }
}


