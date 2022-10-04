resource "proxmox_vm_qemu" "coreos-example" {
    name = "core-os-example"
    desc = "Fedora CORE OS"
    target_node = "homeserver"

    agent = 1

    clone = "coreos"
    cores = 2
    sockets = 1
    cpu = "host"
    memory = 1024

    network {
      bridge = "vmbr0"
      model = "virtio"
    }

    disk {
        storage = "coreos-data-zfs"
        type = "virtio"
        size = "200G"
    }
}