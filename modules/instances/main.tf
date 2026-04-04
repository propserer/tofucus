resource "incus_instance" "vm" {
  name      = var.instance_name
  image     = "images:${var.image}"
  type      = "container"
  running   = true

  config = {
    "boot.autostart" = "true"
    "limits.cpu"     = tostring(var.cpu_limit)
    "limits.memory"  = tostring(var.memory_limit)
    // cloud-init
    "cloud-init.user-data" = templatefile("${path.module}/template/cloud-init.yaml.tftpl", {
      username = var.username
      ssh_key  = var.ssh_key
      timezone = var.timezone
    })
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = var.storage_pool
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype  = var.nic_type
      parent   = var.network_name
      // sets static ip
      "ipv4.address" = var.ipv4_address
    }
  }
}
