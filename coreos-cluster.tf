resource "proxmox_vm_qemu" "coreos_cluster" {
    depends_on = [
        ssh_resource.upload_ignition
    ]
    count = length(var.node_hostnames)
    name = "core-os-${var.node_hostnames[count.index].name}"
    desc = "Fedora CoreOS K8s - ${var.node_hostnames[count.index].name}"
    target_node = var.node_hostnames[count.index].node_name

    agent = 1
    cores = 4
    sockets = 1
    vmid = 190 + count.index
    cpu = "host"
    memory = 4096
    iso = "proxmox-nfs:iso/coreos_${var.node_hostnames[count.index].name}.iso"

    network {
        bridge = "vmbr0"
        model = "virtio"
    }

    disk {
        storage = "local"
        type = "virtio"
        size = "20G"
    }
}