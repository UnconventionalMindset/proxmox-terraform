terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.14"
    }

    ct = {
      source  = "poseidon/ct"
      version = "0.11.0"
    }
    
    ssh = {
      source = "loafoe/ssh"
    }
  }
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

provider "ct" {}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  # Skip TLS
  # pm_tls_insecure = true
}

provider "ssh" {
  debug_log = "ssh_debug.log"
}

variable "cluster" {
  type    = list(object({
    name = string
    ip = string
    node = string
    node_name = string
  }))
  default = [
    {
      name = "master"
      node_name = "elitedesk-1"
      ip = "192.168.31.190"
      node = "192.168.31.85"
    },
    {
      name = "node1"
      node_name = "homeserver"
      ip = "192.168.31.191"
      node = "192.168.31.84"
    },
    {
      name = "node2"
      node_name = "elitedesk-2"
      ip = "192.168.31.192"
      node = "192.168.31.86"
    },
  ]
}

data "ct_config" "coreos_ignition" {
  count = length(var.cluster)

  content = try(templatefile("/home/jac/proxmox-terraform/coreos.yaml", {
    node_hostname = var.node_hostnames[count.index].name
    node_ip       = var.node_hostnames[count.index].ip
  }))
  strict       = true
  pretty_print = true
}


resource "local_file" "coreos_ignition" {
  count = length(var.node_hostnames)

  content  = data.ct_config.coreos_ignition[count.index].rendered
  filename = "output/ignition/coreos_${var.node_hostnames[count.index].name}.ign"
}

resource "ssh_resource" "upload_ignition" {
  depends_on = [
    local_file.coreos_ignition,
  ]
  count = length(var.node_hostnames)

  host         = "192.168.31.123"
  user         = "jac"
  host_user    = "wwwcbz"
  private_key  = templatefile("/home/jac/.ssh/coreos", {})
  timeout      = "30s"

  when         = "create" # Default

  file {
    source      = "/home/jac/proxmox-terraform/${local_file.coreos_ignition[count.index].filename}"
    destination = "/home/www/ignition/coreos_${var.node_hostnames[count.index].name}.ign"
    permissions = "0755"
    owner       = "wwwcbz"
    group       = "wwwcbz"
  }
}