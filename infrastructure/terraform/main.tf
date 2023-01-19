# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  # Note: the OS_* variables in the sourceable environment file are read by the OpenStack provider.
}

locals {
  hostname = "ChaordicLedgerHost"
}

resource "openstack_compute_instance_v2" "chaordicledgerhost" {
  count           = var.instance_count
  name            = "${local.hostname}${count.index + 1}"
  image_name      = "iniStar RHEL 8.6 LTS"
  image_id        = "a1db6c30-e97c-4c8d-b9d2-348224f7c99a"
  flavor_name     = "m1.large"
  key_pair        = "ChaordicLedgerTerraform"
  security_groups = [ "default" ]

  metadata = {
    Name         = "${local.hostname}${count.index + 1}"
    Description  = "ChaordicLedger"
    Subsystem    = "DevOps"
    SubystemType = "ProcessingHost"
    LatestFlag   = true
  }
}

data "template_file" "inventory" {
  template = file("./templates/chaordicledgerhosts.tpl")
  vars = {
    host_ip = join(
      "\n", 
      openstack_compute_instance_v2.chaordicledgerhost[*].network[0].fixed_ip_v4,
    )
  }
}

resource "local_file" "inventoryFile" {
  content  = data.template_file.inventory.rendered
  filename = var.inventoryFile
}
