variable "cloudPassword" {}
variable "cloudUsername" {}
variable "instanceName" {}

provider "vsphere" {
  user           = "${var.cloudUsername}"
  password       = "${var.cloudPassword}"
  vsphere_server = "10.30.21.180"
  version = "~> 1.3.0"
  # if you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "labs-denver-demo"
}

data "vsphere_datastore" "datastore" {
  name          = "vsanDatastore"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "Demo-vSAN/Demo"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "VLAN0002 - Internal Server"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "Morpheus Ubuntu 16.04.3 v1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  name             = "${var.instanceName}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 1
  memory   = 1024
  guest_id = "ubuntu64Guest"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label            = "disk0"
    thin_provisioned = true
    size             = 15
  }

  disk {
    label       = "disk1"
    size        = 5
    unit_number = 1
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
  }

  connection {
    type     = "ssh"
    user     = "cloud-user"
    password = "m0rp#3us!"
  }
}
