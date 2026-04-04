output "container_ip" {
  description = "The IPv4 address of the container"

  // Search for the device named "eth0", that we create in 'modules/instances/main.tf' file
  value = one([
    for d in incus_instance.vm.device : d.properties["ipv4.address"]
    if d.name == "eth0"
  ])
}
